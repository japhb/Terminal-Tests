# ABSTRACT: Output quick single-page terminal test pattern

use Terminal::ANSIColor;
use Terminal::Capabilities;
use Terminal::Capabilities::Autodetect;
use Text::MiscUtils::Layout;


sub summarize-autodetection() {
    my ($caps, $terminal, $version) = terminal-env-detect;

    my $draw  = (('V' if $caps.vt100-boxes),
                 ('H' if $caps.half-blocks),
                 ('Q' if $caps.quadrants),
                 ('S' if $caps.sextants),
                 ('O' if $caps.octants),
                 ('q' if $caps.sep-quadrants),
                 ('s' if $caps.sep-sextants),
                 ('o' if $caps.braille)).join;

    my $rgb   = colored('R', '255,0,0')
              ~ colored('G', '0,255,0')
              ~ colored('B', '100,100,255');
    my $color = $caps.color24bit ??  $rgb  !!
                $caps.color8bit  ??  '256' !!
                $caps.color3bit  ??  'VT'  !! '';
    $color    = colored('B', 'bold white') ~ $color if $caps.colorbright;

    my $attrs = ((colored('B', 'bold')      if $caps.bold),
                 (colored('I', 'italic')    if $caps.italic),
                 (colored('I', 'inverse')   if $caps.inverse),
                 (colored('U', 'underline') if $caps.underline)).join;

    my $summary = $version ?? "$terminal $version" !! $terminal;
    $summary ~= '; symbols:' ~ $caps.symbol-set;
    $summary ~= " attrs:$attrs" if $attrs;
    $summary ~= " color:$color" if $color;
    $summary ~= " drawing:$draw" if $draw;


    colored('Detected:', 'bold yellow') ~ ' ' ~ $summary
}


#| Print a simple baseline terminal test
sub MAIN(
    Bool:D :$ruler = False  #= Show a screen width ruler also
) is export {
    # Autodetection using Terminal::Capabilities::Autodetect
    my $summary = summarize-autodetection;

    # Simple ANSI attributes
    my @basic   = < bold italic inverse underline >;
    my @attrs   = @basic.map: { colored($_, $_) ~ (' ' x 10 - .chars) };

    # 4-bit palette colors
    my @palette = < black red green yellow blue magenta cyan white >;
    my $regular = @palette.map({ colored '██', $_ }).join;
    my $reg-bg  = @palette.map({ colored '██', "inverse on_$_" }).join;
    my $bold    = @palette.map({ colored '██', "bold $_" }).join;
    my $bold-bg = @palette.map({ colored '██', "bold inverse on_$_" }).join;

    # 8-bit greyscale
    my $grey    = (^24).map({ colored ' ', 'on_' ~ (232 + $_) }).join;

    # 24-bit color
    my $red     = (^24).map({ my $s = floor($_ * 255/23);
                              colored ' ', "on_$s,0,0" }).join;
    my $green   = (^24).map({ my $s = floor($_ * 255/23);
                              colored ' ', "on_0,$s,0" }).join;
    my $blue    = (^24).map({ my $s = floor($_ * 255/23);
                              colored ' ', "on_0,0,$s" }).join;

    # Combined color bars
    my @colors  = $regular ~ ' ' ~ $red,
                  $reg-bg  ~ ' ' ~ $green,
                  $bold    ~ ' ' ~ $blue,
                  $bold-bg ~ ' ' ~ $grey;

    # Glyph repertoires
    my $latin1   = < « » ¥ £ ¢ ¤ ¡ ¿ µ ¶ § © ® ° × ÷ ± · ¼ ½ ¾ >.join;
    my $cp1252   = < ‰ † ‡ ™ • … ‹ › € ƒ ‘ ’ “ ” ‚ „ >.join;
    my $w1g      = < ′ ″ ∂ ∆ ∑ ∏ ∫ √ ⅛ ⅜ ⅝ ⅞ ≤ ≥ ≠ ≈ ∞ >.join;
    my $wgl4     = < ↔ ↕ ○ ● □ ■ ▫ ▪ ▬ ⌂ ♪ ♫ ☺ ☻ ♀ ♂ ☼ >.join;
    my $mes2     = < ∧ ∨ ⊕ ⊗ ∩ ∪ ⊂ ⊃ ∈ ∉ ∀ ∃ 〈 〉 >.join;
    my $uni1     = < ˥ ˦ ˧ ˨ ˩ ‼ ‽ ✔ ✘ ⅓ ⅔ ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ >.join;
    my $uni1wide = "⁂ ※ ";
    my $all      = ($latin1, $cp1252, $w1g, $wgl4, $mes2, $uni1, $uni1wide).join;
    my @glyphs   = $all.comb.rotor(27, :partial).map(*.join);

    # Superscripts and subscripts
    my $sub      = (flat  'ₙ',          (0x2080 .. 0x208E).map(&chr)).join;
    my $super    = (flat < ⁿ ⁰ ¹ ² ³ >, (0x2074 .. 0x207E).map(&chr)).join;

    # Game piece glyphs
    my $suits    = < ♠ ♣ ♥ ♦ ♤ ♧ ♡ ♢ >.join;                         # WGL4, Unicode 1.1
    my $chess    = (^12).map({ chr(0x2654 + $_) }).join;             # Unicode 1.1
    my $dice     = < ⚀ ⚁ ⚂ ⚃ ⚄ ⚅ >.join;                             # Unicode 3.2
    my $shogi    = < ☖ ☗ ⛉ ⛊ >.join;                                 # Unicode 3.2, 5.2
    my $draughts = < ⛀ ⛁ ⛂ ⛃ >.join;                                 # Unicode 5.1
    my $hdomino  = (^4).map({ chr(0x1F030 + 13 * $_) ~ ' ' }).join;  # Unicode 5.1
    my $vdomino  = (^4).map({ chr(0x1F062 + 13 * $_) }).join;        # Unicode 5.1
    my $mahjong  = (flat 0x1F007, 0x1F010, 0x1F019,
                    0x1F022 .. 0x1F02B).map({ .chr ~ ' '}).join;     # Unicode 5.1
    my $hearts   = (0x1F0B1 .. 0x1F0BE).map({ .chr ~ ' '}).join;     # Unicode 6.0
    my $trumps   = (flat 0x1F0F0 .. 0x1F0F3, 0x1F0E6 .. 0x1F0E9,
                    0x1F0E1, 0x1F0F5).map({ .chr ~ ' '}).join;       # Unicode 7.0
    my $xiangqi  = (0x1FA60 .. 0x1FA6D).map({ .chr ~ ' '}).join;     # Unicode 11.0
    my @games    = ($suits, $chess, $dice, $shogi, $draughts,
                    $hdomino ~ $vdomino, $mahjong).join(' '),
                   ($hearts, $trumps, $xiangqi).join(' ');

    # Block drawing glyphs
    my $lo-vbars = '▁▂▃▄▅▆▇█';
    my $hi-vbars = '▔🮂🮃▀🮄🮅🮆█';
    my $l-hbars  = '▉▊▋▌▍▎▏';
    my $r-hbars  = '▕🮇🮈▐🮉🮊🮋';
    my $h-lines  = '▔🭶🭷🭸🭹🭺🭻▁';
    my $v-lines  = '▏🭰🭱🭲🭳🭴🭵▕';           # Doesn't display well horizontally
    my @vertical = < ▏ 🭰 🭱 🭲 🭳 🭴 🭵 ▕ >;  # Same set, broken into 8 rows
    my $checker  = '▀▄ 🙿  🮕🮕';
    my $shades   = '██▓▓▒▒░░';
    my $squares  = '◧◨◩◪⬒⬓⬕⬔';
    my $fills    = (0x25A4 .. 0x25A9).map(&chr).join;
    my @blocks   = "$lo-vbars $l-hbars $checker $shades",
                   "$hi-vbars $r-hbars $h-lines $squares";

    # Arrows
    my $sarrows = < → ↗ ↑ ↖ ← ↙ ↓ ↘ >.join;
    my $darrows = < ⇒ ⇗ ⇑ ⇖ ⇐ ⇙ ⇓ ⇘ >.join;
    my $blarrow = < ➡ ⬈ ⬆ ⬉ ⬅ ⬋ ⬇ ⬊ >.join;
    my $carrows = < ↺ ↻ ⟲ ⟳ ⭯ ⭮ >.join;
    my $warrows = < ⇨ ⇧ ⇦ ⇩ >.join;
    my $barrows = < ↦ ↥ ↤ ↧ >.join;
    my $parrows = < ⇉ ⇈ ⇇ ⇊ >.join;
    my $harrows = < 🡆 🡅 🡄 🡇 >.join;
    my @arrows  = ($sarrows, $darrows, $blarrow).join(' '),
                  ($carrows, $warrows, $barrows, $parrows, $harrows).join(' ');

    # Sub-cell "pixel" glyphs
    my $quadrants = < ▘ ▝ ▀ ▖ ▌ ▞ ▛ ▗ ▚ ▐ ▜ ▄ ▙ ▟ █ >.join;
    my $sextants  = (1..15).map({ chr(0x1FB00 + 4 * $_ - 1) }).join;
    my $octants   = (1..15).map({ chr(0x1CD00 + 15 * $_) }).join;
    my $sep-quads = (1..15).map({ chr(0x1CC20 + $_) }).join;
    my $sep-sexts = (1..15).map({ chr(0x1CE50 + 4 * $_) }).join;
    my $sep-octs  = (1..15).map({ chr(0x2800 + 17 * $_) }).join;

    my @sub-cells = '  ' ~ $quadrants ~ 'Q' ~ $sep-quads,
                    '  ' ~ $sextants  ~ 'S' ~ $sep-sexts,
                    '  ' ~ $octants   ~ 'O' ~ $sep-octs;

    # Text and color emoji
    sub textify($char) { $char ~ "\x[FE0E]"  }
    sub emojify($char) { $char ~ "\x[FE0F]"  }
    sub toneify($char) { $char ~ "\x[1F3FF]" }
    my @faces   = < 😵 😲 😍 😠 😑 🤐 🤮 >;
    my @people  = < 👶 🧒 👦 👧 🧑 👨 👩 🧓 👴 👵 >;
    my $texts   = @faces.map(&textify).map(* ~ ' ').join;
    my $emoji   = @faces.map(&emojify).join;
    my $tones   = @people.map(&toneify).join;
    my $faces   = ($texts, $emoji, $tones).join('  ');

    # Emoji flags
    sub countrify($iso-code) {
        $iso-code.uc.comb.map({ chr(ord($_) + 0x1F1A5) }).join
    }
    sub regionify($region) {
        my $reg = $region.lc.subst('-', '').comb.map({ chr(ord($_) + 0xE0000) }).join;
        '🏴' ~ $reg ~ "\xE007F"
    }
    sub zwj(*@chars) { @chars.join("\x200D") }

    my $flags-base = < 🏳 🏳️ 🏴 🏁 🚩 🎌 >.join;
    my $flags-iso  = < cn de es fr gb it jp kr ru us un >.map(&countrify).join;
    my $flags-reg  = < GB-ENG GB-SCT GB-WLS US-CA US-TX >.map(&regionify).join;
    my @flags-zwj  = zwj('🏳️', '🌈'), zwj('🏴', emojify('☠')), zwj('🏳️', emojify('⚧'));
    my $flags-zwj  = @flags-zwj.join;
    my $flags      = ($flags-base, $flags-iso, $flags-reg, $flags-zwj).join(' ');

    # ZWJ people sequences, increasingly complex
    my $farmer     = zwj('👨', '🌾');
    my $surfer     = zwj('🏄', emojify('♀'));
    my $couple     = zwj('👩', emojify('❤'), '👩');
    my $kiss1      = zwj('👩', emojify('❤'), '💋', '👨');
    my $kiss2      = zwj('🧑', emojify('❤'), '💋', '🧑');
    my $people     = $surfer ~ $farmer ~ $couple ~ $kiss1 ~ $kiss2;

    # Box drawing glyphs
    my @boxes =
        '╭┄╮╭╌╮┌─┐┏━┓╔═╗╭┈┬┈╮┌─┬─┐┏━┳━┓╔═╦═╗┏┯┳┯┓╔╤╦╤╗╔╤╦╤╗',
        '┊ ┊╎ ╎│ │┃ ┃║ ║├┈┼┈┤├─┼─┤┣━╋━┫╠═╬═╣┣┿╋┿┫╟┼╫┼╢╠╪╬╪╣',
        '╰┄╯╰╌╯└─┘┗━┛╚═╝╰┈┴┈╯└─┴─┘┗━┻━┛╚═╩═╝┗┷┻┷┛╚╧╩╧╝╚╧╩╧╝';

    # Compass roses
    my @compasses =
        ' ╷   ╻  ╲╿╱   ▲    ⮝   ◸ ▲ ◹',
        '─○─ ━🞉━ ╾╳╼ ◄ ● ►⮜ 🟑 ⮞ ◀ ✵ ▶',
        ' ╵   ╹  ╱╽╲   ▼    ⮟   ◺ ▼ ◿';

    # Patterns
    my @patterns =
        '⌌ ⌍ ◜ ◝ ⌜ ⌝ ◲ ◱ ◶ ◵ 🬚🬓 █▀█ █🮑█ ▛▀▜ 🬕🬂🬨 🬆 🬊 🭽▔🭾',
        '⌎ ⌏ ◟ ◞ ⌞ ⌟ ◳ ◰ ◷ ◴ 🬂🬀 ▀▀▀ ▀▀▀ ▙▄▟ 🬲🬭🬷 🬱 🬵 🭼▁🭿';

    # Combined output
    my @top     = ^4 .map: { @attrs[$_] ~ @colors[$_] ~ ' ' ~ @glyphs[$_] };
    my @rows    = $summary, '', |@top, '',
                  |(@vertical Z~ (|@games, '', |(@blocks Z~
                                                 (' ' ~ $sub   ~ ' ' ~ @arrows[0],
                                                  ' ' ~ $super ~ ' ' ~ @arrows[1])),
                                  |(@boxes Z~ @compasses))),
                  |((|@patterns, ' ' x 46) Z~ @sub-cells),
                  $faces, $flags, $people;

    .say for @rows;
    say horizontal-ruler if $ruler;
}
