# ABSTRACT: Output quick single-page terminal test pattern

use Terminal::ANSIColor;
use Text::MiscUtils::Layout;


#| Print a simple baseline terminal test
sub MAIN(
    Bool:D :$ruler = False  #= Show a screen width ruler also
) is export {
    # Simple ANSI attributes
    my @basic  = < bold italic inverse underline >;
    my @attrs  = @basic.map: { colored($_, $_) ~ (' ' x 11 - .chars) };

    # 4-bit palette colors
    my @palette = < black red green yellow blue magenta cyan white >;
    my $regular = @palette.map({ colored '  ', "inverse $_" }).join;
    my $bold    = @palette.map({ colored '  ', "bold inverse $_" }).join;

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
    my @colors  = $regular ~ '  ' ~ $red,
                  $regular ~ '  ' ~ $green,
                  $bold    ~ '  ' ~ $blue,
                  $regular ~ '  ' ~ $grey;

    # Glyph repertoires
    my $latin1  = < £ ¥ « » ¡ ¿ µ ¶ × ÷ § © ® ° ± · ¹ ² ³ ¼ ½ ¾ >.join;
    my $cp1252  = < • … € ƒ ‹ › † ‡ ™ ‰ ‘ ’ “ ” ‚ „ >.join;
    my $w1g     = < ′ ″ ⅛ ⅜ ⅝ ⅞ ∆ ∂ ∞ ∑ ∏ ∫ ≈ ≠ ≤ ≥ √ ⁿ >.join;
    my $wgl4    = < ← ↑ → ↓ ↔ ↕ ○ ● □ ■ ▫ ▪ ▲ ▼ ◄ ► ♠ ♣ ♥ ♦ ♪ ♫ ☺ ☻ ⌂ ☼ ♀ ♂ >.join;
    my $mes2    = < ∀ ∃ ∧ ∨ ⊕ ⊗ ∩ ∪ ⊂ ⊃ ∈ ∉ >.join;
    my $all     = ($latin1, $cp1252, $w1g, $wgl4, $mes2).join;
    my @glyphs  = $all.comb.rotor(24, :partial).map(*.join);

    # Block drawing glyphs
    my $vbars   = '▁▂▃▄▅▆▇█';
    my $hbars   = '▉▊▋▌▍▎▏';
    my $checker = '▀▄';
    my $shades  = '██  ▓▓  ▒▒  ░░';
    my $blocks  = "$vbars  $hbars $checker  $shades";

    # Misc symbols
    my $tbars   = '˥ ˦ ˧ ˨ ˩';
    my $sarrows = '→ ↗ ↑ ↖ ← ↙ ↓ ↘';
    my $darrows = '⇒ ⇗ ⇑ ⇖ ⇐ ⇙ ⇓ ⇘';
    my $symbols = "$tbars $sarrows $darrows";
    my $misc    = "$blocks  $symbols";

    # Text and color emoji
    sub textify($char) { $char ~ "\x[FE0E]"  }
    sub emojify($char) { $char ~ "\x[FE0F]"  }
    sub toneify($char) { $char ~ "\x[1F3FF]" }
    my @faces   = < 😵 😲 😍 😠 😑 🤐 🤮 >;
    my @people  = < 👶 🧒 👦 👧 🧑 👨 👩 🧓 👴 👵 >;
    my $texts   = @faces.map(&textify).join(' ');
    my $emoji   = @faces.map(&emojify).join(' ');
    my $tones   = @people.map(&toneify).join(' ');
    my $faces   = '  ' ~ ($texts, $emoji, $tones).join('   ');

    # Box drawing glyphs
    my @boxes   =
        '╭┄╮  ╭╌╮  ┌─┐  ┏━┓  ╔═╗  ╭┈┬┈╮  ┌─┬─┐  ┏━┳━┓  ╔═╦═╗  ┏┯┳┯┓  ┏┯┳┯┓  ╔╤╦╤╗  ╔╤╦╤╗',
        '┊ ┊  ╎ ╎  │ │  ┃ ┃  ║ ║  ├┈┼┈┤  ├─┼─┤  ┣━╋━┫  ╠═╬═╣  ┠┼╂┼┨  ┣┿╋┿┫  ╟┼╫┼╢  ╠╪╬╪╣',
        '╰┄╯  ╰╌╯  └─┘  ┗━┛  ╚═╝  ╰┈┴┈╯  └─┴─┘  ┗━┻━┛  ╚═╩═╝  ┗┷┻┷┛  ┗┷┻┷┛  ╚╧╩╧╝  ╚╧╩╧╝';

    # Patterns
    my @patterns =
        '⌌ ⌍  ◜ ◝  ⌜ ⌝  ◲ ◱  ◶ ◵   🬚🬓  █▀█  █🮑█  ▛▀▜  🬕🬂🬨  🬆 🬊  🭽▔🭾    ▲      ⮝    ◸ ▲ ◹',
        '⌎ ⌏  ◟ ◞  ⌞ ⌟  ◳ ◰  ◷ ◴   🬂🬀  ▀▀▀  ▀▀▀  ▙▄▟  🬲🬭🬷  🬱 🬵  🭼▁🭿  ◄ ● ►  ⮜ 🟑 ⮞  ◀ ✵ ▶',
        '                                                              ▼      ⮟    ◺ ▼ ◿';

    # Combined output
    my @top     = ^4 .map: { @attrs[$_] ~ @colors[$_] ~ '  ' ~ @glyphs[$_] };
    my @rows    = '', |@top, '', $misc, '', |@boxes, '', |@patterns, '', $faces, '';

    .say for @rows;
    say horizontal-ruler if $ruler;
}
