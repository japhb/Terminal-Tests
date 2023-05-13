# ABSTRACT: Detailed survey-style terminal/font quality tests

use Hash::Ordered;
use JSON::Fast;
use Terminal::ANSIColor;
use Text::MiscUtils::Layout;


### MAIN TEST AND RESULT ROUTINES

my %answer is Hash::Ordered;

sub clear() {
    print "\e[H\e[2J\e[3J";
}

sub show($section, $name, $title, $desc, @rows) {
    clear;
    put $section.uc ~ ": $title\n";
    .indent(4).put for @rows;
    put "\nYOU SHOULD SEE:\n";
    put $desc.indent(4);
    my $prompt = colored("How well does the display match the description? (0-3) ", 'bold');

    my $answer;
    repeat {
        $answer = +(prompt($prompt).?trim);
    } until $answer ~~ Int && 0 <= $answer <= 3;

    %answer{$section} //= Hash::Ordered.new;
    %answer{$section}{$name} = $answer;
}

#| Last test key in a given section that scored *at least* $threshold
sub last-at-least($threshold, $section, @keys) {
    my $last;
    for @keys {
        my $score = try %answer{$section}{$_}.Numeric;
        last unless $score.defined && $score >= $threshold;
        $last = $_;
    }

    $last
}

sub show-answers() {
    clear;

    # Try to look nice *if* the test results confirm it's possible
    my $icons  = %answer<symbols><basic> // 0;
    my $colors = %answer<color><4-bit> // 0;
    my $attrs  = %answer<color><attributes> // 0;

    my @icons  = $icons  > 1 ?? < ✘ ~ + ✔ > !! < - ~ + * >;
    my @colors = $colors > 1 ?? < red red yellow green > !!
                 $attrs  > 1 ?? ('inverse', 'inverse', '', 'bold') !! ();

    for %answer.kv -> $section, %tests {
        put $section.uc;
        for %tests.kv -> $test, $result {
            my $icon    = @icons[ $result];
            my $color   = @colors[$result];
            my $colored = $color ?? colored($icon, $color) !! $icon;
            put "  $colored $test";
        }
        put '';
    }
}

sub result-data() {
    my %results is Hash::Ordered =
        meta => Hash::Ordered.new(
            'kernel'    => $*KERNEL.name,
            'terminal'  => %*ENV<TERM>,
            'timestamp' => DateTime.now,
        ),
        answers => %answer,
        summaries => Hash::Ordered.new(
            'symbols' => summarize-symbols,
        );
}

sub print-json-results() {
    put to-json result-data;
}


### INTRO

sub show-intro() {
    clear;
    put q:to/INTRO/;
        TERMINAL QUALITY TEST

        This program will help you test the visual quality of your terminal emulator
        and completeness of your selected fonts.

        It will show a series of screens with different patterns drawn near the top,
        with a description below.  You can then assess how well the displayed pattern
        matches the description on a simple quality scale:

          0. Completely broken or nothing but replacement markers shown
          1. Partially working; some pieces correct and others missing or incorrect
          2. Mostly correct, with only minor artifacts or uneven spots
          3. Very good quality, exactly as described

        After rating all test screens, a summary of the results will be printed.
        INTRO

    prompt colored("Press enter when ready to begin. ", 'bold');
}


### COLOR TESTS

sub show-basic-attributes() {
    my @basic = < bold italic inverse underline >;
    my @rows  = @basic.map: { colored $_, $_ };
    my $desc  = qq:to/DESC/;
        The words "bold", "italic", "inverse", and "underline", each on
        a line by itself, and each displayed as self-described. In other
        words, "bold" should appear bold (thicker), "italic" should appear
        italic (slanted or in a proper italic font), and so on.
        DESC
    show('color', 'attributes', "Attributes", $desc, @rows);
}

sub show-four-bit-color() {
    my @colors = < black red green yellow blue magenta cyan white >;
    my @fg     = @colors.map: { colored '██',         $_ };
    my @bg     = @colors.map: { colored '  ', 'on_' ~ $_ };
    my @rows   = @fg.join,
                 @bg.join,
                 @fg.map({ BOLD() ~ $_ }).join,
                 @bg.map({ BOLD() ~ $_ }).join;
    my $desc   = qq:to/DESC/;
        Eight solid colored stripes, from left to right:

            {@colors.join(', ')}

        There should be a lighter stripe across all colors
        between half and three-quarters of the way down.  There
        should be no gaps or faint lines within the stripes.

        NOTE: Some terminal themes will alter stripe colors.
        DESC
    show('color', '4-bit', "4-Bit (16 color)", $desc, @rows);
}

sub show-eight-bit-color() {
    my @colors = 16..231;
    my @rows   = @colors.rotor(36).map(*.map({ colored '██', ~$_ }).join);
    my $desc   = q:to/DESC/;
        Six large colored blocks, each made of six-by-six smaller
        colored squares.  The leftmost large block should have black,
        blue, red, and magenta at the corners.  The rightmost large
        block should have green, cyan, yellow, and white at the corners.

        All squares should appear the same size, and no "merged" squares
        should be visible anywhere.  Each small square should be solid,
        with no gaps or faint lines.
        DESC
    show('color', '8-bit', "8-Bit (256 color)", $desc, @rows);
}

sub show-greyscale-color() {
    my @colors = 232..255;
    my $row    = @colors.map({ colored '██', ~$_ }).join;
    my $desc   = q:to/DESC/;
        A ramp from dark to bright of grey squares with 24 grey levels.
        All squares should appear the same size, and no "merged" blocks
        should be visible anywhere.  Squares should appear solid, with
        no internal gaps or faint lines.
        DESC
    show('color', 'greyscale', "Greyscale", $desc, [$row]);
}

sub show-full-color() {
    my @values = 0..255;
    my @rows;
    @rows.append: @values.rotor(64).map(*.map({ colored '█', "$_,0,0" }).join);
    @rows.append: @values.rotor(64).map(*.map({ colored '█', "0,$_,0" }).join);
    @rows.append: @values.rotor(64).map(*.map({ colored '█', "0,0,$_" }).join);
    my $desc   = q:to/DESC/;
        Smooth ramps from black to bright red, green, and blue, each over
        four rows.  Along each row, color variation should appear quite
        smooth, with no strong color banding, gaps, or faint lines visible
        within any row.
        DESC
    show('color', '24-bit', "24-Bit (standard color)", $desc, @rows);
}


### BLOCK AND BOX-DRAWING TESTS

# XXXX: Separate block drawing by glyph repertoire generation:
#       upper/lower/full+light/medium/heavy (DONE!),
#       left/right-half, ... (eighths?)
sub show-simple-blocks() {
    my @rows;
    @rows.push: < ██ ▓▓ ▒▒ ░░ >;
    @rows.push: < >;
    @rows.push: ('▀▄', colored('▄▀', 'inverse'),
                 colored('▀▄', 'white on_black'),
                 colored('▄▀', 'black on_white'));
    my $desc = q:to/DESC/;
        Two rows of four square patterns; from left to right the top row
        should show solid, dense, medium, and light shaded squares.  Each
        square should be evenly shaded, with no gaps or faded lines.

        The second row should show checkerboards; the left two should be
        identical, and the right two should likewise be identical.  If your
        terminal is set for white foreground, black background, AND standard
        4-bit colors, all four checkerboards should appear identical.
        DESC
    show('drawing', 'simple-blocks', "Simple Blocks", $desc, @rows);
}

sub show-vertical-bar-graph-blocks() {
    my @rows;
    @rows.push: '▁▂▃▄▅▆▇█' ~ colored('▔', 'inverse') ~ '▆▅▄▃▂▁';
    @rows.push: '███████████████';
    @rows.push: '▔' ~ colored('▆▅▄▃▂▁ ▁▂▃▄▅▆▇', 'inverse');
    my $desc = q:to/DESC/;
        A 6-sided figure, looking somewhat like a wide horizontal diamond
        with left and right tips truncated.  There should be no gaps or
        faint lines within the shape, and the left and right halves should
        ramp evenly up and down and be perfectly mirror-symmetrical.  The
        top and bottom halves should also be perfectly mirror-symmetrical.
        DESC
    show('drawing', 'vertical-bars', "Vertical Bar Graphs", $desc, @rows);
}

sub show-horizontal-bar-graph-blocks() {
    my @rows;
    @rows.push: ' █' ~ colored('█', 'inverse');
    @rows.push: '▕█▏';
    @rows.push: colored('▊', 'inverse') ~ '█▎';
    @rows.push: colored('▋', 'inverse') ~ '█▍';
    @rows.push: colored('▌', 'inverse') ~ '█▌';
    @rows.push: colored('▍', 'inverse') ~ '█▋';
    @rows.push: colored('▎', 'inverse') ~ '█▊';
    @rows.push: colored('▏', 'inverse') ~ '█▉';
    @rows.push: '██' ~ colored(' ', 'inverse');

    my $desc = q:to/DESC/;
        A narrow and tall trapezoid, wider on the bottom; there should be
        no gaps or faint lines within the shape, and the left and right
        halves should ramp evenly and be perfectly mirror-symmetrical.
        DESC
    show('drawing', 'horizontal-bars', "Horizontal Bar Graphs", $desc, @rows);
}

# XXXX: Separate line drawing by glyph repertoire generation:
#       simple thin single, outer-frame-only double, simple double, (ALL DONE!)
#       single-double combo, ... (heavy? dashed? rounded?)

# XXXX: What happens when line drawing characters are bolded?
#       ==> Bitmap xterm does bright double-strike, others do nothing
sub show-simple-boxes() {
    my @rows =
    < ┌───┐ ╔═══╗ ┌─┬─┐ ╔═╦═╗ >,
    < │┌─┐│ ║╔═╗║ │ │ │ ║ ║ ║ >,
    < ││ ││ ║║ ║║ ├─┼─┤ ╠═╬═╣ >,
    < │└─┘│ ║╚═╝║ │ │ │ ║ ║ ║ >,
    < └───┘ ╚═══╝ └─┴─┘ ╚═╩═╝ >;
    my $desc = q:to/DESC/;
        Four rectangular boxes shown in different styles; starting on the left:

          * Small box within larger box, both with solid thin lines
          * Small box within larger box, both with doubled lines
          * Window pane with four sub-panes, all with solid thin lines
          * Window pane with four sub-panes, all with doubled lines

        All of the lines should be straight with square corners, and with no
        gaps or waving lines.
        DESC
    show('drawing', 'simple-boxes', "Simple Boxes", $desc, @rows);
}

sub show-styled-boxes() {
    my @rows =
    < ╭╌┬╌╮ ┌─┬─┐ ┏━┳━┓ ╔═╦═╗ >,
    < ╎ ╎ ╎ │ │ │ ┃ ┃ ┃ ║ ║ ║ >,
    < ├╌┼╌┤ ├─┼─┤ ┣━╋━┫ ╠═╬═╣ >,
    < ╎ ╎ ╎ │ │ │ ┃ ┃ ┃ ║ ║ ║ >,
    < ╰╌┴╌╯ └─┴─┘ ┗━┻━┛ ╚═╩═╝ >;
    my $desc = q:to/DESC/;
        Four boxes shown in "window pane" style, starting on the left:

          * Rounded corners and dashed thin lines
          * Square corners and solid thin lines
          * Square corners and solid thick lines
          * Square corners and solid doubled lines

        ONLY the leftmost box should have any gaps in the lines, and all
        intersections and horizontal and vertical lines should be straight.
        DESC
    show('drawing', 'styled-boxes', "Styled Boxes", $desc, @rows);
}

sub show-complex-boxes() {
    my @rows =
    ' ┏┯┳┯┓   ╔═╦═╗  ',
    ' ┠┼╂┼┨  ┌╫┬╫┬╫┐ ',
    ' ┣┿╋┿┫  │╠╪╬╪╣│ ',
    ' ┠┼╂┼┨  ├╫┼╫┼╫┤ ',
    ' ┗┷┻┷┛  ╘╩╧╩╧╩╛ ';
    my $desc = q:to/DESC/;
        Two windows in different styles.  The left window has four
        thick-bordered panes, each divided into four thin-bordered
        sub-panes.  All sub-panes should appear identical in size.

        The right window has doubled lines, a window sill, and a
        safety railing in front.  The thin lines of the railing should
        clearly cross over the doubled window lines behind them, with
        no gap in the single line.  All lines on both windows should be
        straight, with no gaps or waving lines.
        DESC
    show('drawing', 'complex-boxes', "Complex Boxes", $desc, @rows);
}


### ICON/SYMBOL TESTS

# Early symbol repertoires, in STRICT SUPERSET ORDER

#| Original ASCII, once the printables were all defined (1967?)
sub show-ascii-printables() {
    my @rows;
    @rows.push: (0x20..0x3F).map(&chr);
    @rows.push: (0x40..0x5F).map(&chr);
    @rows.push: (0x60..0x7E).map(&chr);
    my $desc = q:to/DESC/;
        The full original ASCII printable character set in three rows;
        the first row should have a blank spot at the beginning, and
        the third row should have a blank spot at the end.

        ASCII printables are the most widely supported characters, so
        you will most likely see all expected glyphs in the expected
        order.  However you may still see artifacts because of the
        font used by your terminal; a perfect score requires clear
        differentiation between uppercase I, lowercase l, and digit 1,
        as well as between uppercase O and digit 0.
        DESC
    show('symbols', 'ascii', "ASCII Printables", $desc, @rows);
}

#| ISO-8859-1, AKA Latin-1, the default character set of HTML 4
sub show-latin1-symbols() {
    my @rows;
    @rows.push: < ¤ ¢ £ ¥ « » >;
    @rows.push: < ¡ ¿ µ ¶ × ÷ >;
    @rows.push: < § © ® ° ± · >;
    @rows.push: < ¹ ² ³ ¼ ½ ¾ >;
    my $desc = q:to/DESC/;
        Four rows of symbols and punctuation; from left to right on each row:

          * currency: general, cent, pound, yen; quotes: double-guillemets
          * inverted: exclamation, question; micro, pilcrow, multiply, divide
          * section, copyright, registered, degrees, plus-minus, mid-dot
          * superscripts: 1, 2, 3; fractions: 1/4, 1/2, 3/4
        DESC
    show('symbols', 'latin1', "ISO-8859-1 (Latin-1)", $desc, @rows);
}

#| CP1252, AKA Windows-1252, the default character set of HTML 5
sub show-cp1252-symbols() {
    my @rows;
    @rows.push: < € ƒ ™ ‰ – — >;
    @rows.push: < † ‡ • … ‹ › >;
    @rows.push: < ‘ ’ “ ” ‚ „ >;
    my $desc = q:to/DESC/;
        Three rows of symbols and punctuation; from left to right on each row:

          * currency: euro, florin; trademark, per-mille, en-dash, em-dash
          * dagger, double-dagger, bullet, ellipsis, single-guillemets
          * single-curly-quotes, double-curly-quotes, low-curly-quotes
        DESC
    show('symbols', 'cp1252', "CP1252 (Windows-1252)", $desc, @rows);
}

#| Math symbols from the intersection of W1G and WGL4 (full WGL4 is next)
sub show-w1g-math-symbols() {
    my @rows;
    @rows.push: < ⅛ ⅜ ⅝ ⅞ ′ ″ >;
    @rows.push: < ∆ ∂ ∞ ∑ ∏ ∫ >;
    @rows.push: < ≈ ≠ ≤ ≥ √ ⁿ >;
    my $desc = q:to/DESC/;
        Three rows of mathematical symbols; from left to right on each row:

          * fractions: 1/8, 3/8, 5/8, 7/8; primes: single, double
          * increment, differential, infinity, sum, product, integral
          * approximately, not-equal, less-than-or-equal, greater-than-or-equal,
            square-root, superscript-n
        DESC
    show('symbols', 'w1g-math', "W1G/WGL4 Math", $desc, @rows);
}

#| Miscellaneous symbols from full WGL4 (also see box and block drawing)
sub show-wgl4-symbols() {
    my @rows;
    @rows.push: < ← ↑ → ↓ ↔ ↕ >;
    @rows.push: < ○ ● □ ■ ▫ ▪ >;
    @rows.push: < ▲ ▼ ◄ ► ◊ ▬ >;
    @rows.push: < ♠ ♣ ♥ ♦ ♪ ♫ >;
    @rows.push: < ☺ ☻ ⌂ ☼ ♀ ♂ >;
    my $desc = q:to/DESC/;
        A row of orthogonal small arrows, two rows of shapes, and two rows of
        symbols; from left to right on each row:

          * arrows pointing: left, up, right, down, left-right, up-down
          * outline and solid shapes: circle, square, small-square
          * triangles pointing: up, down, left, right; lozenge, rectangle
          * card suits: spade, club, heart, diamond; quavers: single, double
          * smiling faces: outline, solid; symbols: house, sun, female, male
        DESC
    show('symbols', 'wgl4', "WGL4 Other", $desc, @rows);
}

#| Math symbols from MES-2 ("Multilingual European Subset No. 2")
sub show-mes2-math-symbols() {
    my @rows;
    # XXXX: Angle brackets have non-unit width
    @rows.push: < ∀ ∃ 〈 〉 >;
    @rows.push: < ∧ ∨ ⊕ ⊗ >;
    @rows.push: < ∩ ∪ ⊂ ⊃ ∈ ∉ >;
    my $desc = q:to/DESC/;
        Three rows of mathematical symbols; from left to right on each row:

          * quantifiers: for-all, there-exists; angle brackets: left, right
          * operators: logical-and, logical-or, circled-plus, circled-times
          * sets: intersection, union, subset, superset, element, not-element
        DESC
    show('symbols', 'mes2-math', "MES-2 Math", $desc, @rows);
}

sub summarize-symbols() {
    my @keys = < ascii latin1 cp1252 w1g-math wgl4 mes2-math >;
    my $good = last-at-least(3, 'symbols', @keys);
    my $okay = last-at-least(2, 'symbols', @keys);
    my $poor = last-at-least(1, 'symbols', @keys);

    { :$good, :$okay, :$poor }
}


# Unicode 1.1 symbols not (fully) from previous repertoires

#| Number Forms (fractions and Roman numerals)
sub show-number-forms() {
    my @rows;
    @rows.push: < ⅓ ⅔ ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ >;
    @rows.push: (0x2160 .. 0x216B).map(&chr);
    @rows.push: (0x2170 .. 0x217B).map(&chr);
    @rows.push: < Ⅼ Ⅽ Ⅾ Ⅿ ⅼ ⅽ ⅾ ⅿ >;
    my $desc = q:to/DESC/;
        Four rows of number forms; from left to right on each row:

          * fractions: 1/3, 2/3, 1/5, 2/5, 3/5, 4/5, 1/6, 5/6
          * Roman numeral uppercase: I-XII
          * Roman numeral lowercase: i-xii
          * Roman numeral larger numbers: L, C, D, M, l, c, d, m
        DESC
    show('symbols', 'number-forms', "Number Forms", $desc, @rows);
}

#| Superscript and subscript digits (superscript 1,2,3 were already in Latin-1)
sub show-super-sub-digits() {
    my @rows;
    @rows.push: flat < X ⁰ ¹ ² ³ >, (0x2074 .. 0x207E).map(&chr), 'X';
    @rows.push: flat  'X',          (0x2080 .. 0x208E).map(&chr), 'X';
    my $desc = q:to/DESC/;
        A row each of superscripts and subscripts, with leading and trailing
        capital letter X for position reference; each row has left to right:

          * digits: 0-9; plus, minus, equals; parenthesis: left, right

        If only the superscript 1, 2, 3 (and X's) appear this rates as 0,
        as these are inherited from Latin-1 instead of being new glyphs.
        DESC
    show('symbols', 'super-sub-digits', "Superscript and Subscript Digits", $desc, @rows);
}

#| Tone bars
sub show-tone-bars() {
    my @rows;
    @rows.push: < ˥ ˦ ˧ ˨ ˩ >;
    my $desc = q:to/DESC/;
        A row of tone bars; from left to right:

          * extra-high, high, mid, low, extra-low
        DESC
    show('symbols', 'tone-bars', "Tone Bars", $desc, @rows);
}

# XXXX: Currency Symbols (20A0-20CF)

# XXXX: Letterlike Symbols (2100-214F)

# XXXX: Mathematical Operators (2200-22FF)

# XXXX: Miscellaneous Technical (2300-23FF)

# XXXX: Enclosed Alphanumerics (2460-24FF)

# XXXX: Geometric Shapes (25A0-25FF)

# XXXX: Braille (2800-28FF)

# XXXX: EDIT
sub show-basic-icons() {
    my @rows;
    @rows.push: < ✔ ✘ ‣ ⁂ >;
    @rows.push: < ※ ‼ ‽ ‱ >;
    @rows.push: < ‖ ‗ ‾ ‿ >;
    my $desc = q:to/DESC/;
        Three rows of icons and punctuation; from left to right on each row:

          * checkmark, ballot-x, triangle-bullet, asterism
          * reference-mark, double-exclamation, interrobang, per-ten-thousand
          * double-vertical-bar, double-low-bar, overbar, undertie
        DESC
    show('symbols', 'basic', "Misc", $desc, @rows);
}

#| Icons indicating various types of danger
sub show-danger-icons() {
    my @rows;
    @rows.push: < ☇ ☠ ☢ ☣ >;
    @rows.push: < ⚠ ⚛ ⚰ ⚱ >;
    my $desc = q:to/DESC/;
        Two rows of danger-related icons; from left to right on each row:

          * lightning, skull+crossbones, radioactive, biohazard
          * warning-triangle, atom, coffin, urn
        DESC
    show('symbols', 'danger', "Danger", $desc, @rows);
}


### ARROW TESTS

# XXXX: Arrows (2190-21FF)
#       Unicode 1.1 extras: 219A-21EA
#       Unicode 3.0: 21EB-21F3
#       Unicode 3.2: 21F4-21FF

sub show-small-arrows() {
    my @rows;
    @rows.push: < → ↗ ↑ ↖ ← ↙ ↓ ↘ >;
    my $desc = q:to/DESC/;
        A row of SMALL arrows, rotating counter-clockwise from left to right.
        The arrows should all appear roughly the same length, and none of
        them should be cut off at the tip or tail.
        DESC
    show('arrows', 'small', "Small", $desc, @rows);
}

sub show-double-arrows() {
    my @rows;
    @rows.push: < ⇒ ⇗ ⇑ ⇖ ⇐ ⇙ ⇓ ⇘ >;
    my $desc = q:to/DESC/;
        A row of DOUBLE arrows, rotating counter-clockwise from left to right.
        The arrows should all appear roughly the same length, and none of
        them should be cut off at the tip or tail.
        DESC
    show('arrows', 'double', "Double", $desc, @rows);
}

sub show-heavy-arrows() {
    my @rows;
    @rows.push: < 🢂 🢅 🢁 🢄 🢀 🢇 🢃 🢆 >;
    my $desc = q:to/DESC/;
        A row of HEAVY arrows, rotating counter-clockwise from left to right.
        The arrows should all appear roughly the same length, and none of
        them should be cut off at the tip or tail.
        DESC
    show('arrows', 'heavy', "Heavy", $desc, @rows);
}


### GAME PIECE TESTS

# XXXX: Extended chess (Unicode 12.0, 1FA00-1FA53)

#| Basic Chess Pieces (Unicode 1.1)
sub show-chess-pieces() {
    my @rows;
    @rows.push: (0x2654 .. 0x2659).map(&chr);
    @rows.push: (0x265A .. 0x265F).map(&chr);
    my $desc = q:to/DESC/;
        Two rows of chess pieces (white and black) in text outline form;
        from left to right on each row:

          * king, queen, rook, bishop, knight, pawn

        Pieces should not be cut off or unreadable.  Spacing should be even,
        with no extra-wide or extra-narrow gaps.
        DESC
    show('games', 'chess', "Chess", $desc, @rows);
}

#| Game pieces for various common games (Unicode 1.1, 3.2, 5.1, 5.2)
sub show-misc-game-pieces() {
    my @rows;
    @rows.push: < ♡ ♢ ♤ ♧ >;
    @rows.push: < ⚀ ⚁ ⚂ ⚃ ⚄ ⚅ >;
    @rows.push: < ☖ ☗ ⛉ ⛊ >;
    @rows.push: < ⛀ ⛁ ⛂ ⛃ >;
    my $desc = q:to/DESC/;
        Four rows of game pieces in text outline form; from left to right
        on each row:

          * card suit outlines: heart, diamond, spade, club
          * six-sided die faces: 1-6
          * white and black shogi pieces: upright, turned
          * white and black draughts pieces: man, king

        Pieces should not be cut off or unreadable.  Spacing should be even,
        with no extra-wide or extra-narrow gaps.
        DESC
    show('games', 'misc', "Misc", $desc, @rows);
}

#| Mahjong Tiles (Unicode 5.1)
sub show-mahjong-tiles() {
    my @rows;
    @rows.push: (0x1F000 .. 0x1F006).map(&chr).map(&textify);
    @rows.push: (0x1F007 .. 0x1F00F).map(&chr);
    @rows.push: (0x1F010 .. 0x1F018).map(&chr);
    @rows.push: (0x1F019 .. 0x1F021).map(&chr);
    @rows.push: (0x1F022 .. 0x1F02B).map(&chr);
    my $desc = q:to/DESC/;
        Five rows of mahjong tiles in text outline form; from top to bottom:

          * winds: east, south, west, north; dragons: red, green, white
          * characters: 1-9
          * bamboos:    1-9
          * circles:    1-9
          * flowers: plum, orchid, bamboo, chrysanthemum;
            seasons: spring, summer, autumn, winter; other: joker, back

        Tiles should not be cut off or unreadable.  Spacing should be even,
        with no extra-wide or extra-narrow gaps.
        DESC
    show('games', 'mahjong', "Mahjong", $desc, @rows);
}

#| Domino Tiles (Unicode 5.1)
sub show-domino-tiles() {
    my @rows;
    @rows.push:      (0x1F031 .. 0x1F04C).map(&chr);
    @rows.push: (flat 0x1F04D .. 0x1F061, 0x1F030).map(&chr);
    @rows.push: '';
    @rows.push:      (0x1F063 .. 0x1F07E).map(&chr);
    @rows.push: (flat 0x1F07F .. 0x1F093, 0x1F062).map(&chr);
    my $desc = q:to/DESC/;
        Four rows of domino tiles in text outline form; from top to bottom:

          * horizontal tiles: 0-0 to 3-6
          * horizontal tiles: 4-0 to 6-6, back
          * vertical tiles:   0-0 to 3-6
          * vertical tiles:   4-0 to 6-6, back

        Tiles should not be cut off or unreadable.  Spacing should be even,
        with no extra-wide or extra-narrow gaps.
        DESC
    show('games', 'dominoes', "Dominoes", $desc, @rows);
}

#| Standard Playing Cards (Unicode 6.0)
sub show-playing-cards() {
    my @rows;
    @rows.push: (0x1F0A1 .. 0x1F0AE).map(&chr);
    @rows.push: (0x1F0B1 .. 0x1F0BE).map(&chr);
    @rows.push: (0x1F0C1 .. 0x1F0CE).map(&chr);
    @rows.push: (0x1F0D1 .. 0x1F0DE).map(&chr);
    @rows.push: (0x1F0A0, 0x1F0BF, 0x1F0CF, 0x1F0DF).map(&chr).map(&textify);
    my $desc = q:to/DESC/;
        Five rows of playing cards in text outline form; from top to bottom:

          * spades:   ace, 2-10, jack, knight, queen, king
          * hearts:   ace, 2-10, jack, knight, queen, king
          * diamonds: ace, 2-10, jack, knight, queen, king
          * clubs:    ace, 2-10, jack, knight, queen, king
          * card back; jokers: red, black, white

        Cards should not be cut off or unreadable.  Spacing should be even,
        with no extra-wide or extra-narrow gaps.
        DESC
    show('games', 'playing-cards', "Playing Cards", $desc, @rows);
}

#| Playing Card Trumps (Unicode 7.0)
sub show-playing-card-trumps() {
    my @rows;
    @rows.push: (0x1F0E2 .. 0x1F0E5).map(&chr);
    @rows.push: (0x1F0F0 .. 0x1F0F3).map(&chr);
    @rows.push: (0x1F0E6 .. 0x1F0E9).map(&chr);
    @rows.push: (0x1F0EC .. 0x1F0EF).map(&chr);
    @rows.push: (0x1F0EA, 0x1F0EB, 0x1F0E1, 0x1F0F5, 0x1F0E0, 0x1F0F4).map(&chr);
    my $desc = q:to/DESC/;
        Five rows of playing card trumps in text outline form; from left to
        right on each row:

          * ages: childhood, youth, maturity, old-age
          * seasons: spring, summer, autumn, winter
          * times: morning, afternoon, evening, night
          * activities: dance, shopping, open-air, visual-arts
          * pairs: earth-and-air, water-and-fire, individual, collective,
            the-fool, the-game

        Cards should not be cut off or unreadable.  Spacing should be even,
        with no extra-wide or extra-narrow gaps.
        DESC
    show('games', 'trump-cards', "Trump Cards", $desc, @rows);
}

#| Xiangqi Pieces (Unicode 11.0)
sub show-xiangqi-pieces() {
    my @rows;
    @rows.push: (0x1FA60 .. 0x1FA66).map(&chr);
    @rows.push: (0x1FA67 .. 0x1FA6D).map(&chr);
    my $desc = q:to/DESC/;
        Two rows of xiangqi pieces (red and black) in text outline form;
        from left to right on each row:

          * general, mandarin, elephant, horse, chariot, cannon, soldier

        Pieces should not be cut off or unreadable.  Spacing should be even,
        with no extra-wide or extra-narrow gaps.
        DESC
    show('games', 'xiangqi', "Xiangqi", $desc, @rows);
}



#     @rows.push: < ▤ ▥ ▦ ▧ ▨ ▩ >;
#     @rows.push: < ֍ ֎ >;
# ⚕


### EMOJI TESTS

my constant %icons =
    # Deactivations
    dead      => '💀',
    petrified => '',
    sleeping  => '💤',
    paralyzed => '⌁',
    stunned   => '😵',
    surprised => '😲',

    # Mental states
    confused  => '⁈',
    charmed   => '😍',
    enraged   => '😠',
    calmed    => '😑',

    # Disablements
    blinded   => '▆',
    silenced  => '🤐',
    nauseated => '🤮',

    # Debuffs
    burning   => '🔥',
    freezing  => '❄',
    poisoned  => '🕱',
    infected  => '☣',
    bleeding  => '🌢',
    drained   => '-',

    # Buffs
    boosted   => '+',
    regen     => '⚕',
    protected => '⛨',
    hasted    => '🏃',
;

sub fixup($char, $mod, $expected-width = 0) {
    my $spacer = ' ' x max 0, $expected-width - duospace-width($char);
    $char ~ $mod ~ $spacer
}

sub emojify($char)        { fixup($char, "\x[FE0F]", 2) }
sub textify($char)        { fixup($char, "\x[FE0E]") }
sub toneify($char, $tone) { fixup($char, chr(0x1f3f9 + $tone), 2) }

my @faces = < stunned surprised charmed enraged calmed silenced nauseated >;

# XXXX: Reverse or RGB outlines?
sub show-facial-outlines() {
    my $row = @faces.map({ textify(%icons{$_}) });
    my $desc = qq:to/DESC/;
        A row of seven face emoji showing conditions, all in text/icon
        outline form; from left to right:

          * {@faces.join(', ')}
        DESC
    show('emoji', 'face-outlines', "Face Outlines", $desc, [$row]);
}

sub show-facial-expressions() {
    my $row = @faces.map({ emojify(%icons{$_}) });
    my $desc = qq:to/DESC/;
        A row of seven face emoji showing conditions, all with default
        (solid yellow) "skin" color; from left to right:

          * {@faces.join(', ')}
        DESC
    show('emoji', 'face-emoji', "Faces", $desc, [$row]);
}

#| Skin tones (Unicode 6.0 and Unicode 10.0 bases, Unicode 8.0 Fitzpatrick tones)
sub show-skin-tones() {
    my @people = < 👶 🧒 👦 👧 🧑 👨 👩 🧓 👴 👵 >;
    my @rows;
    for 2..6 -> $tone {
        @rows.push: @people.map({ toneify($_, $tone) });
    }
    my $desc = q:to/DESC/;
        Five rows of ten faces, ranging from light skin tone at the top to
        dark skin tone at the bottom.  Each row's faces are, left to right:

          * baby, child, boy, girl, adult, man, woman; older: adult, man, woman

        If you see yellow faces next to separate tone swatches, this rates as 1.
        DESC
    show('emoji', 'skin-tones', "Skin Tones", $desc, @rows);
}

sub show-equipment() {
    my @equip = < dagger shield bow >;
    my $row = @equip.map({ emojify(%icons{$_}) });
    my $desc = qq:to/DESC/;
        A row of equipment emoji; from left to right:

          * {@equip.join(', ')}
        DESC
    show('emoji', 'face-emoji', "Faces", $desc, [$row]);
}


### MAIN DRIVER

sub MAIN(Bool :$json) is export {
    # Intro/instructions
    show-intro;

    # Color tests
    show-basic-attributes;
    show-four-bit-color;
    show-eight-bit-color;
    show-greyscale-color;
    show-full-color;

    # Block and box-drawing tests
    show-simple-blocks;
    show-vertical-bar-graph-blocks;
    show-horizontal-bar-graph-blocks;

    show-simple-boxes;
    show-styled-boxes;
    show-complex-boxes;

    # Icon and symbol tests
    show-ascii-printables;
    show-latin1-symbols;
    show-cp1252-symbols;
    show-w1g-math-symbols;
    show-wgl4-symbols;
    show-mes2-math-symbols;

    show-number-forms;
    show-super-sub-digits;
    show-basic-icons;
    show-tone-bars;
    show-danger-icons;

    # Arrow tests
    show-small-arrows;
    show-double-arrows;
    show-heavy-arrows;

    # Game piece tests
    show-chess-pieces;
    show-misc-game-pieces;
    show-mahjong-tiles;
    show-domino-tiles;
    show-playing-cards;
    show-playing-card-trumps;
    show-xiangqi-pieces;

    # Emoji tests
    show-facial-outlines;
    show-facial-expressions;
    show-skin-tones;

    # Show results
    $json ?? print-json-results() !! show-answers;
}
