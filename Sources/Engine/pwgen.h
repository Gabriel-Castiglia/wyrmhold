/**
  Wyrmhold -- the engine.
  Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
  Date: November 9, 2026
  SPDX-License-Identifier: GPL-2.0-only

  Three kinds of password:

    PW_CHARS   random characters. Any of the four classes (lowercase, uppercase, digits,
               symbols) can be switched off; the symbols come from a chosen set (a basic
               set of eleven, all 32 printable ASCII symbols, a minimal "- _ ." set
               for strict sites, or the user's own). Optional: leave out the ambiguous
               0 O 1 l I, leave out any characters the user lists, never repeat a character
               twice in a row, always start with a letter.
    PW_WORDS   a passphrase: words drawn from the EFF large word list (7776 words, about
               12.9 bits each), a separator, optional capitals and one digit.
    PW_PIN     digits only, optionally with no repeated neighbours and no runs such as
               123 or 987.

  How a password is drawn (the "algorithm"):

    Every character (or word) comes from arc4random_buf, the macOS cryptographic random
    number generator, through rejection sampling, so each one is exactly equally likely --
    a plain "x % n" would favour the first few. For PW_CHARS and PW_PIN the whole password
    is drawn at once and thrown away when it breaks a rule (a required class missing, a
    repeated neighbour, a run...), then drawn again. That makes the result uniform over
    *every* password that obeys the rules -- no position, class or pattern is more likely
    than another -- which a "one of each class, then shuffle" method would only
    approximate. pw_entropy() counts those passwords exactly (by dynamic programming over
    the positions), so the strength shown is the real one, not length * log2(pool).

  The defaults (pw_defaults) are the standard profile: 20 characters, the four classes,
  the symbols !@#$%&*+-=?, no 0 O 1 l I.
**/

#ifndef PWGEN_H
#define PWGEN_H

#define PW_MIN_LEN    4       /* characters, and PIN digits */
#define PW_MAX_LEN    128
#define PW_MIN_WORDS  3
#define PW_MAX_WORDS  12
#define PW_OUT_MAX    200     /* the longest password any setting can produce, plus the zero */
#define PW_SET_MAX    96      /* a character set: printable ASCII is 95 */

#define PW_SYMBOLS      "!@#$%&*+-=?"                          /* the basic set */
#define PW_SYMBOLS_ALL  "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"   /* every printable ASCII symbol */
#define PW_SYMBOLS_MIN  "-_."                                  /* accepted by almost every site */
#define PW_AMBIGUOUS    "0O1lI|`'\""

enum { PW_CHARS = 0, PW_WORDS = 1, PW_PIN = 2 };
enum { PW_SYM_BASIC = 0, PW_SYM_ALL = 1, PW_SYM_MIN = 2, PW_SYM_CUSTOM = 3 };
enum { PW_SEP_HYPHEN = 0, PW_SEP_SPACE, PW_SEP_DOT, PW_SEP_UNDERSCORE, PW_SEP_NONE, PW_SEP_DIGIT, PW_SEP_COUNT };

/* What pw_check() can object to. */
enum { PW_OK = 0, PW_ERR_NOCLASS, PW_ERR_EMPTYCLASS, PW_ERR_TOOSHORT, PW_ERR_NODIGITS };

typedef struct {
	int mode;                       /* PW_CHARS, PW_WORDS or PW_PIN */

	/* PW_CHARS */
	int length;
	int lower, upper, digits, symbols;
	int symbolSet;                  /* PW_SYM_* */
	char customSymbols[PW_SET_MAX]; /* used with PW_SYM_CUSTOM; anything not a printable symbol is ignored */
	int avoidAmbiguous;
	char exclude[PW_SET_MAX];       /* characters never to use (chars and PIN) */
	int noRepeat;                   /* no character twice in a row (chars and PIN) */
	int startLetter;                /* the first character is a letter */

	/* PW_WORDS */
	int words;
	int separator;                  /* PW_SEP_* */
	int capitalize;                 /* Each Word Starts With A Capital */
	int addNumber;                  /* one digit after one of the words */

	/* PW_PIN */
	int pinLength;
	int noSequence;                 /* no three digits in a row going up or down by one: 123, 987 */
} PwOptions;

/* The standard profile, plus sensible defaults for the other two kinds. */
void pw_defaults(PwOptions* o);

/* PW_OK, or why these options cannot make a password. `which` (may be NULL) receives the
 * class that ended up empty for PW_ERR_EMPTYCLASS: 0 lower, 1 upper, 2 digits, 3 symbols. */
int pw_check(const PwOptions* o, int* which);

/* Writes one password and its terminating zero into out[PW_OUT_MAX]. Returns its length,
 * or 0 if the options are impossible or the random number generator failed (out is then
 * emptied). Lengths are clamped to their ranges. */
int pw_make(const PwOptions* o, char* out);

/* log2 of the number of different passwords these options can produce (exact for
 * characters and PINs, all rules included). 0 if impossible. */
double pw_entropy(const PwOptions* o);

/* How many different characters a position can take (characters and PIN), or the number
 * of words in the list (passphrases). */
int pw_pool(const PwOptions* o);

/* The symbols in use, after the set, the ambiguous ones and the exclusions. out[PW_SET_MAX]. */
void pw_symbols_in_use(const PwOptions* o, char* out);

/* Number of words in the built-in list, and one of them (for the test tools). */
int pw_word_count(void);
const char* pw_word(int i);

/* The standard rules with a given length and choice of ambiguous characters. */
int pw_generate(int length, int avoidAmbiguous, char* out);

#endif
