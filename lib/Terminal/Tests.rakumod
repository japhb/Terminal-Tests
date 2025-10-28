unit class Terminal::Tests;


=begin pod

=head1 NAME

Terminal::Tests - Terminal emulator, multiplexer, and font quality tests


=head1 SYNOPSIS

=begin code :lang<shell>

$ terminal-quick-test [--ruler]
# ... single-page test output ...

$ terminal-test
# ... multi-page survey-style test ...

=end code


=head1 DESCRIPTION

Terminal::Tests is a collection of quality and correctness tests for terminal
emulators, terminal multiplexers, Unicode configurations, and monospace fonts.

The simple C<terminal-quick-test> program displays a simple test pattern that
should fit in a default 80x24 terminal window, and will catch some of the most
common terminal configuration problems.  For a more nuanced test, try the full
C<terminal-test> program, which shows numerous test patterns and describes what
you should expect to see in each.


=head2 Quick Test Pattern

To display the quick test program, simply run C<terminal-quick-test>; you can
add the C<--ruler> option if you'd like to also display a screen width ruler
to help detect misalignment.  I<Correct> output should be no more than 79
columns on any line, so you've likely run into a terminal bug if the displayed
test pattern is wider than that.

At the time of writing, I've not yet seen any terminals show a perfect test
pattern; the best results so far still have a few issues but get most of the
big things good enough.  Here's the top contender so far, as of October 2025:

L<Screenshot of quick test on Ghostty 1.2.2 using DejaVu Sans Mono font|docs/images/quick-test-ghostty-1.2.2-dejavu-sans-mono-ruler.png>

That's Ghostty 1.2.2 with C<font-family> set to "DejaVu Sans Mono", running on
Linux Mint 22.2 (Zara), which is based on Ubuntu 24.04 LTS (Noble Numbat).
There are a few issues here and there, but overall it looks pretty good.

For comparison, here's the default C<gnome-terminal> (3.52.0 using VTE 0.76.0)
running on the same Linux Mint 22.2 system:

L<Screenshot of quick test on default gnome-terminal with ruler|docs/images/quick-test-gnome-terminal-ruler.png>

The rightmost block of face emoji should have skin tones applied, rather than
shown in fallback mode as a tone swatch next to a yellow emoji, and the spacing
on the text-mode (outline) faces is too wide, causing the line to stretch.
Likewise, flags for ISO country codes are unsupported, while oddly region-coded
flags are, and joined emoji (using ZWJ, the Zero-Width Joiner) don't actually
join.  Furthermore several sets of "big pixel" drawing characters are
unsupported and just show up as codepoint numbers, and the circled numbers in
the ruler are drawn double-width.

On the plus side, C<gnome-terminal> correctly shows the bright bar in the 3-bit
color bars section in the upper left, doesn't stretch the outlined corner
triangles in the right most "compass rose" block, and produces more readable
and balanced line-drawing glyphs.

In between these is Kovid Goyal's kitty 0.32.2:

L<Screenshot of quick test on kitty with ruler|docs/images/quick-test-kitty-ruler.png>

C<kitty> does much better than C<gnome-terminal> with emoji and handles facial
skin tones properly.  While country flags are supported, region flags aren't.
Joined emoji are supported, though the spacing is increasingly off as they get
more complex, and some joined emoji sequences don't join properly.  There are
minor artifacts and misalignments on the window frames and boxes, the bright
bar on the basic colors is missing, and again three of the "big pixel" glyph
sets are missing.  Still, this is overall not bad.


=head3 Terminal Multiplexers

Terminal multiplexers such as Zellij, C<tmux>, and GNU Screen tend to cause
relatively subtle failures, affecting only one or two features.  Here's an
example of the test pattern as seen inside of GNU Screen in a C<gnome-terminal>:

L<Screenshot of quick test running inside GNU Screen on gnome-terminal|docs/images/quick-test-gnome-terminal-gnu-screen-ruler.png>

There are two new degradations here, compared to C<gnome-terminal> by itself.
The first is that GNU Screen supports 4-bit and 8-bit SGR color, but not 24-bit
color, so the red/green/blue bars in the top middle are missing.  The second is
that GNU Screen has replaced the italic attribute with inverse at the top left.
(I remain mystified as to why it does this, but it is at least consistent in
doing so.)

C<tmux> also causes some minor degradations, though different ones than GNU Screen:

L<Screenshot of quick test running inside tmux on gnome-terminal|docs/images/quick-test-gnome-terminal-tmux-ruler.png>

Instead of completely removing the RGB bars, C<tmux> seems to map them down to
an 8-bit palette instead, causing strong banding.  It also seems to change the
emoji spacing in odd ways so that some emoji entirely disappear, seemingly
overwritten by their neighbors.

Interestingly, C<tmux>'s corruption is different when run on Ghostty.  This
time it doesn't seem to affect the RGB color bars at all, but instead flag
handling goes completely batty:

L<Screenshot of quick test running inside tmux on Ghostty|docs/images/quick-test-ghostty-1.2.2-tmux-ruler.png>


=head3 Font Troubles

I specified the C<font-family> for Ghostty above because the default font for
Ghostty 1.2.2 is "JetBrains Mono"; that font is unfortunately missing quite a
few glyphs, causing Ghostty to try to fill in from other fonts.  This generally
makes a bit of a mismatch mess; there's more detailed discussion in
L<Ghostty's issue #9161|https://github.com/ghostty-org/ghostty/discussions/9161>,
but here's what it looks like:

L<Screenshot of quick test on Ghostty 1.2.2 using JetBrains Mono font|docs/images/quick-test-ghostty-1.2.2-jetbrains-mono-ruler.png>

Notice how glyph sizes become inconsistent, several glyphs (including most of
the vulgar fractions and arrows) overlap each other, the heart card suit and
white chess pawn look different than their fellows, and so on.

As font problems go, this is pretty minor however.  There's even a benefit:
this is the first screenshot that shows programming ligatures working (see the
row of glyphs just above the emoji faces).

For a whole different scale of font problems, consider C<xterm> for example.
By default on my Linux system if you just run C<xterm>, it will use a low-res
B<bitmap> "fixed" font with approximately Unicode 3.0 support:

L<Screenshot of quick test running on xterm using the Unicode fixed font|docs/images/quick-test-xterm-fixed-unicode-ruler.png>

Many of the symbols are nearly unreadable, most of the advanced drawing
characters are missing, and emoji aren't supported at all.  Seems bad.

But it gets worse!  Specifying a larger bitmap font size defaults to using the
I<non-Unicode> version of the font.  Here I've launched C<xterm -fn 10x20>:

L<Screenshot of quick test running on xterm using the Latin-1 fixed font|docs/images/quick-test-xterm-fixed-latin1-ruler.png>

This font is essentially limited to the Latin-1 repertoire, plus the most
ancient VT-100 drawing characters.  Almost everything is empty boxes, even the
ruler at the bottom.

Using a scalable font will work better, even at the default small size, but
color emoji are still unsupported (only text outlines are shown), and many of
the glyphs are misaligned or cut off.  Here I've just told C<xterm> to use the
default system monospace scalable font using C<xterm -fa mono>:

L<Screenshot of quick test running on xterm using the mono scalable font|docs/images/quick-test-xterm-mono-ruler.png>

Unsurprisingly the scalable font scales up better too (using C<xterm -fa mono -fs 12>):

L<Screenshot of quick test running on xterm using the mono scalable font at 12-point size|docs/images/quick-test-xterm-mono-12-ruler.png>



=head3 Non-UTF-8 Configurations

Windows Terminal in Windows 10 can produce a relatively decent result aside
from the emoji rows, but B<only> if "beta" UTF-8 support is turned on (see
separate L<#Windows 10 Terminal> section below).  Without that, the test
pattern will absolutely fall apart:

L<Screenshot of quick test on Windows Terminal in UTF-16 mode|docs/images/quick-test-windows-terminal-default.png>

That screenshot is actually from a much earlier version of the quick-test
pattern, but the encoding garbage completely overwhelms everything anyway, so
it's a bit of a moot point.


=head3 OS and Terminal Versions

Operating system and terminal software versions can make a significant
difference.  For example, here's Terminal on macOS 10.14:

L<Screenshot of quick test running on Terminal on macOS 10.14|docs/images/quick-test-macOS10.14-Terminal.png>

There's a massive improvement moving to Terminal on macOS 12.6:

L<Screenshot of quick test running on Terminal on macOS 12.6|docs/images/quick-test-macOS12.6-Terminal.png>

And another overall quality improvement switching to iTerm2 on macOS:

L<Screenshot of quick test running on iTerm2 on macOS|docs/images/quick-test-macOS-iterm2.png>

iTerm2 isn't purely an improvement over Terminal; there are a few minor
degradations as well, such as shaded blocks being the wrong size, dashed lines
being offset vertically, square corners being lengthened, and some text symbols
gaining unrequested color.


=head2 Full Terminal Test

The C<terminal-test> program includes a far more complete set of test patterns
across a range of categories, including descriptions of what you should expect
to see in each pattern, as well as common artifacts that you should ideally
I<not> see.  You can rate the display of each pattern on a simple scale, and
the program will summarize the results in text or JSON (with the C<--json>
option) after you have rated the last test pattern.


=head2 Terminal-Specific Recommended Tweaks

=head3 Windows 10 Terminal

By default Windows Terminal under Windows 10 supports only UTF-16, an old
Unicode encoding that has otherwise been replaced by the UTF-8 encoding.
You'll need to change the settings for Windows Terminal to use UTF-8 instead.
(Backwards compatibility with ancient software is certainly a thing, but modern
terminal-interface software doesn't really speak anything but UTF-8 anymore.)

I used to point to online instructions for this, but unfortunately they have
disappeared and the Wayback Machine did not archive them.  Please contact me
if you have replacement instructions.

=head3 Ghostty 1.2.x

For best results change Ghostty's base font; the default used in 1.2.x produces
numerous artifacts.  DejaVu Sans Mono seems to work well on Linux; if you're on
a Mac or Windows box you may need to either install that font family or find
another mostly-complete monospace font family instead instead.

To use a different font, you can set Ghostty's C<font-family>, either in the
config file (C<~/.config/ghostty/config> on Linux) or directly using a
command-line option to C<ghostty>:

    ghostty --font-family="DejaVu Sans Mono"


=head1 AUTHOR

Geoffrey Broadwell <gjb@sonic.net>


=head1 COPYRIGHT AND LICENSE

Copyright © 2022-2025 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod
