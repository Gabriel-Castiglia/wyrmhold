/**
  Wyrmhold -- the engine. See pwgen.h for the rules and the method.
  Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
  Date: November 9, 2026
  SPDX-License-Identifier: GPL-2.0-only
**/

#define __STDC_WANT_LIB_EXT1__ 1   /* memset_s */
#include <math.h>
#include <stdlib.h>   /* arc4random_buf */
#include <string.h>
#include <stdint.h>

#include "pwgen.h"
#include "wordlist.h"

/* A rule set can be possible yet so tight that most draws fail (a 4-character password
 * that needs all four classes from a tiny symbol set accepts about 1 draw in 70). Far more
 * tries than any real setting needs; pw_check() has already ruled out the impossible ones. */
#define MAX_TRIES 2000000

/* ------------------------------------------------------------------ random numbers */

/* A uniform integer in [0, n). Values from the top of the 32-bit range that would make
 * the low results more likely are thrown away and drawn again. The bits come from
 * arc4random_buf, the macOS cryptographic random number generator, fed by the kernel; it
 * cannot fail, so the 0 return is kept only for the shape shared with the Windows engine. */
static int randomBelow(unsigned n, unsigned* out)
{
	const uint64_t span = 0x100000000ULL;
	const uint64_t limit = span - (span % n);
	uint32_t x;

	for (;;)
	{
		arc4random_buf(&x, sizeof(x));
		if ((uint64_t)x < limit) { *out = (unsigned)(x % n); return 1; }
	}
}

/* ------------------------------------------------------------------ character classes */

enum { C_LOWER = 0, C_UPPER, C_DIGIT, C_SYMBOL, C_COUNT };

typedef struct {
	char set[C_COUNT][PW_SET_MAX];
	int n[C_COUNT];                 /* 0 = class off, or emptied by the exclusions */
	int on[C_COUNT];                /* switched on by the user */
	char pool[PW_SET_MAX * 2];
	signed char classOf[128];       /* class of each pool character, -1 if not in the pool */
	int nPool;
} Classes;

static int isSymbolChar(int c) { return c > 32 && c < 127 && !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')); }

static void symbolSource(const PwOptions* o, char* out)
{
	const char* src = o->symbolSet == PW_SYM_ALL ? PW_SYMBOLS_ALL :
	                  o->symbolSet == PW_SYM_MIN ? PW_SYMBOLS_MIN :
	                  o->symbolSet == PW_SYM_CUSTOM ? o->customSymbols : PW_SYMBOLS;
	int n = 0, i;

	/* printable symbols only, each once, in printable-ASCII order */
	for (i = 33; i < 127; i++)
		if (isSymbolChar(i) && memchr(src, i, strnlen(src, PW_SET_MAX))) out[n++] = (char)i;
	out[n] = 0;
}

/* Keeps the characters of `in` that are neither excluded nor (when asked) ambiguous. */
static int filterInto(const char* in, const PwOptions* o, int ambiguousToo, char* out)
{
	int n = 0;

	for (; *in; in++)
	{
		if (memchr(o->exclude, *in, strnlen(o->exclude, PW_SET_MAX))) continue;
		if (ambiguousToo && strchr(PW_AMBIGUOUS, *in)) continue;
		out[n++] = *in;
	}
	out[n] = 0;
	return n;
}

static void buildClasses(const PwOptions* o, Classes* c)
{
	char sym[PW_SET_MAX];
	int k, i;

	memset(c, 0, sizeof(*c));
	memset(c->classOf, -1, sizeof(c->classOf));
	symbolSource(o, sym);

	c->on[C_LOWER] = o->lower;  c->on[C_UPPER] = o->upper;
	c->on[C_DIGIT] = o->digits; c->on[C_SYMBOL] = o->symbols;

	if (o->lower)   c->n[C_LOWER]  = filterInto("abcdefghijklmnopqrstuvwxyz", o, o->avoidAmbiguous, c->set[C_LOWER]);
	if (o->upper)   c->n[C_UPPER]  = filterInto("ABCDEFGHIJKLMNOPQRSTUVWXYZ", o, o->avoidAmbiguous, c->set[C_UPPER]);
	if (o->digits)  c->n[C_DIGIT]  = filterInto("0123456789", o, o->avoidAmbiguous, c->set[C_DIGIT]);
	if (o->symbols) c->n[C_SYMBOL] = filterInto(sym, o, o->avoidAmbiguous, c->set[C_SYMBOL]);

	for (k = 0; k < C_COUNT; k++)
		for (i = 0; i < c->n[k]; i++)
		{
			c->classOf[(unsigned char)c->set[k][i]] = (signed char)k;
			c->pool[c->nPool++] = c->set[k][i];
		}
	c->pool[c->nPool] = 0;
}

/* The first character must be a letter only when letters are available at all. */
static int lettersRequired(const PwOptions* o, const Classes* c)
{
	return o->startLetter && (c->n[C_LOWER] + c->n[C_UPPER]) > 0;
}

static void pinDigits(const PwOptions* o, char* out)
{
	filterInto("0123456789", o, 0, out);
}

static int clampInt(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

/* ------------------------------------------------------------------ counting (entropy) */

/* Numbers of passwords reach 10^250, so the counts are kept scaled: after every position
 * the largest entry is divided out and its log2 added to `acc`. */
static void rescale(double* v, int n, double* acc)
{
	double m = 0;
	int i;

	for (i = 0; i < n; i++) if (v[i] > m) m = v[i];
	if (m <= 0) return;
	for (i = 0; i < n; i++) v[i] /= m;
	*acc += log2(m);
}

/* Characters: state = (classes seen so far, class of the last character). Within a class
 * every character behaves alike, so this counts exactly, repeats and first letter included. */
static double charsEntropy(const PwOptions* o)
{
	Classes c;
	double v[16][C_COUNT], w[16][C_COUNT], acc = 0, total = 0;
	int req = 0, len = clampInt(o->length, PW_MIN_LEN, PW_MAX_LEN), m, k, d, i;

	buildClasses(o, &c);
	for (k = 0; k < C_COUNT; k++) if (c.n[k]) req |= 1 << k;
	if (!req) return 0;

	memset(v, 0, sizeof(v));
	for (k = 0; k < C_COUNT; k++)
	{
		if (!c.n[k]) continue;
		if (lettersRequired(o, &c) && k != C_LOWER && k != C_UPPER) continue;
		v[1 << k][k] = c.n[k];
	}

	for (i = 1; i < len; i++)
	{
		memset(w, 0, sizeof(w));
		for (m = 0; m < 16; m++)
			for (k = 0; k < C_COUNT; k++)
			{
				if (v[m][k] == 0) continue;
				for (d = 0; d < C_COUNT; d++)
				{
					int ways = c.n[d] - ((o->noRepeat && d == k) ? 1 : 0);
					if (ways > 0) w[m | (1 << d)][d] += v[m][k] * ways;
				}
			}
		memcpy(v, w, sizeof(v));
		rescale(&v[0][0], 16 * C_COUNT, &acc);
	}

	for (k = 0; k < C_COUNT; k++) total += v[req][k];
	return total > 0 ? acc + log2(total) : 0;
}

enum { STEP_OTHER = 0, STEP_UP, STEP_DOWN };

/* PIN: state = (last digit, was the last step +1, -1 or anything else). */
static double pinEntropy(const PwOptions* o)
{
	char dg[16];
	double v[10][3], w[10][3], acc = 0, total = 0;
	int len = clampInt(o->pinLength, PW_MIN_LEN, PW_MAX_LEN), nd, i, a, b, s;

	pinDigits(o, dg);
	nd = (int)strlen(dg);
	if (!nd) return 0;

	memset(v, 0, sizeof(v));
	for (a = 0; a < nd; a++) v[dg[a] - '0'][STEP_OTHER] = 1;

	for (i = 1; i < len; i++)
	{
		memset(w, 0, sizeof(w));
		for (a = 0; a < 10; a++)
			for (s = 0; s < 3; s++)
			{
				if (v[a][s] == 0) continue;
				for (b = 0; b < nd; b++)
				{
					int e = dg[b] - '0', step = e - a;
					int ns = step == 1 ? STEP_UP : step == -1 ? STEP_DOWN : STEP_OTHER;
					if (o->noRepeat && step == 0) continue;
					if (o->noSequence && ns != STEP_OTHER && ns == s) continue;
					w[e][ns] += v[a][s];
				}
			}
		memcpy(v, w, sizeof(v));
		rescale(&v[0][0], 30, &acc);
	}

	for (a = 0; a < 10; a++) for (s = 0; s < 3; s++) total += v[a][s];
	return total > 0 ? acc + log2(total) : 0;
}

static double wordsEntropy(const PwOptions* o)
{
	int n = clampInt(o->words, PW_MIN_WORDS, PW_MAX_WORDS);
	double bits = n * log2((double)WORD_COUNT);

	if (o->separator == PW_SEP_DIGIT) bits += (n - 1) * log2(10.0);
	if (o->addNumber) bits += log2(10.0 * n);
	return bits;
}

double pw_entropy(const PwOptions* o)
{
	if (pw_check(o, NULL) != PW_OK) return 0;
	return o->mode == PW_WORDS ? wordsEntropy(o) : o->mode == PW_PIN ? pinEntropy(o) : charsEntropy(o);
}

/* ------------------------------------------------------------------ options */

void pw_defaults(PwOptions* o)
{
	memset(o, 0, sizeof(*o));
	o->mode = PW_CHARS;
	o->length = 20;
	o->lower = o->upper = o->digits = o->symbols = 1;
	o->symbolSet = PW_SYM_BASIC;
	o->avoidAmbiguous = 1;
	o->words = 6;
	o->separator = PW_SEP_HYPHEN;
	o->capitalize = 1;
	o->addNumber = 1;
	o->pinLength = 6;
	o->noSequence = 1;
}

int pw_check(const PwOptions* o, int* which)
{
	if (which) *which = -1;

	if (o->mode == PW_WORDS) return PW_OK;

	if (o->mode == PW_PIN)
	{
		char dg[16];
		pinDigits(o, dg);
		if (!dg[0]) return PW_ERR_NODIGITS;
		if (pinEntropy(o) <= 0) return PW_ERR_TOOSHORT;
		return PW_OK;
	}

	{
		Classes c;
		int k, any = 0;

		buildClasses(o, &c);
		for (k = 0; k < C_COUNT; k++)
		{
			if (!c.on[k]) continue;
			any = 1;
			if (!c.n[k]) { if (which) *which = k; return PW_ERR_EMPTYCLASS; }
		}
		if (!any) return PW_ERR_NOCLASS;
		if (charsEntropy(o) <= 0) return PW_ERR_TOOSHORT;
	}
	return PW_OK;
}

int pw_pool(const PwOptions* o)
{
	if (o->mode == PW_WORDS) return WORD_COUNT;
	if (o->mode == PW_PIN) { char dg[16]; pinDigits(o, dg); return (int)strlen(dg); }
	{ Classes c; buildClasses(o, &c); return c.nPool; }
}

void pw_symbols_in_use(const PwOptions* o, char* out)
{
	Classes c;

	buildClasses(o, &c);
	memcpy(out, c.set[C_SYMBOL], (size_t)c.n[C_SYMBOL] + 1);
}

int pw_word_count(void) { return WORD_COUNT; }
const char* pw_word(int i) { return (i >= 0 && i < WORD_COUNT) ? WORDS[i] : ""; }

/* ------------------------------------------------------------------ drawing passwords */

static int makeChars(const PwOptions* o, char* out)
{
	Classes c;
	int len = clampInt(o->length, PW_MIN_LEN, PW_MAX_LEN), req = 0, k, tries, i;
	int letterFirst;

	buildClasses(o, &c);
	letterFirst = lettersRequired(o, &c);
	for (k = 0; k < C_COUNT; k++) if (c.n[k]) req |= 1 << k;

	for (tries = 0; tries < MAX_TRIES; tries++)
	{
		int seen = 0, good = 1;

		for (i = 0; i < len; i++)
		{
			unsigned j;
			if (!randomBelow((unsigned)c.nPool, &j)) return 0;
			out[i] = c.pool[j];
		}

		/* the whole draw is kept or thrown away: uniform over every valid password */
		for (i = 0; i < len && good; i++)
		{
			int cls = c.classOf[(unsigned char)out[i]];
			seen |= 1 << cls;
			if (i == 0 && letterFirst && cls != C_LOWER && cls != C_UPPER) good = 0;
			if (i > 0 && o->noRepeat && out[i] == out[i - 1]) good = 0;
		}
		if (good && seen == req) { out[len] = 0; return len; }
	}
	return 0;
}

static int makePin(const PwOptions* o, char* out)
{
	char dg[16];
	int len = clampInt(o->pinLength, PW_MIN_LEN, PW_MAX_LEN), nd, tries, i;

	pinDigits(o, dg);
	nd = (int)strlen(dg);

	for (tries = 0; tries < MAX_TRIES; tries++)
	{
		int good = 1;

		for (i = 0; i < len; i++)
		{
			unsigned j;
			if (!randomBelow((unsigned)nd, &j)) return 0;
			out[i] = dg[j];
		}
		for (i = 1; i < len && good; i++)
		{
			int step = out[i] - out[i - 1];
			if (o->noRepeat && step == 0) good = 0;
			if (o->noSequence && i >= 2 && (step == 1 || step == -1) && out[i - 1] - out[i - 2] == step) good = 0;
		}
		if (good) { out[len] = 0; return len; }
	}
	return 0;
}

static int makeWords(const PwOptions* o, char* out)
{
	static const char SEP[PW_SEP_COUNT] = { '-', ' ', '.', '_', 0, 0 };
	int n = clampInt(o->words, PW_MIN_WORDS, PW_MAX_WORDS), len = 0, i;
	unsigned numberAfter = 0, digit = 0;

	if (o->addNumber && (!randomBelow((unsigned)n, &numberAfter) || !randomBelow(10, &digit))) return 0;

	for (i = 0; i < n; i++)
	{
		unsigned w;
		const char* word;
		int start = len;

		if (!randomBelow(WORD_COUNT, &w)) return 0;
		word = WORDS[w];
		while (*word) out[len++] = *word++;
		if (o->capitalize && out[start] >= 'a' && out[start] <= 'z') out[start] = (char)(out[start] - 'a' + 'A');
		if (o->addNumber && (unsigned)i == numberAfter) out[len++] = (char)('0' + digit);

		if (i < n - 1)
		{
			if (o->separator == PW_SEP_DIGIT)
			{
				unsigned d;
				if (!randomBelow(10, &d)) return 0;
				out[len++] = (char)('0' + d);
			}
			else if (SEP[o->separator]) out[len++] = SEP[o->separator];
		}
	}
	out[len] = 0;
	return len;
}

int pw_make(const PwOptions* o, char* out)
{
	int n = 0;

	if (pw_check(o, NULL) == PW_OK)
		n = o->mode == PW_WORDS ? makeWords(o, out) : o->mode == PW_PIN ? makePin(o, out) : makeChars(o, out);
	if (!n) memset_s(out, PW_OUT_MAX, 0, PW_OUT_MAX);
	return n;
}

int pw_generate(int length, int avoidAmbiguous, char* out)
{
	PwOptions o;

	pw_defaults(&o);
	o.length = length;
	o.avoidAmbiguous = avoidAmbiguous;
	return pw_make(&o, out);
}
