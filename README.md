[![Actions Status](https://github.com/japhb/Terminal-Tests/actions/workflows/test.yml/badge.svg)](https://github.com/japhb/Terminal-Tests/actions)

NAME
====

Terminal::Tests - Terminal emulator, multiplexer, and font quality tests

SYNOPSIS
========

```shell
$ terminal-quick-test [--ruler]
# ... single-page test output ...

$ terminal-test
# ... multi-page survey-style test ...
```

DESCRIPTION
===========

Terminal::Tests is a collection of quality and correctness tests for terminal emulators, terminal multiplexers, Unicode configurations, and monospace fonts.

The simple `terminal-quick-test` program displays a simple test pattern that should fit in a default 80x24 terminal window, and will catch some of the most common terminal configuration problems. For a more nuanced test, try the full `terminal-test` program, which shows numerous test patterns and describes what you should expect to see in each.

Quick Test Pattern
------------------

To display the quick test program, simply run `terminal-quick-test`; you can add the `--ruler` option if you'd like to also display a screen width ruler to help detect misalignment. *Correct* output should be no more than 79 columns on any line, so you've likely run into a terminal bug if the displayed test pattern is wider than that.

At the time of writing, I've not yet seen any terminals show a perfect test pattern; the best results so far get everything except the emoji rows correct. For reference, here's what the pattern looks like on a default `gnome-terminal` in Ubuntu 22.04 LTS or Linux Mint 21.x (based on that same Ubuntu LTS release):

![Screenshot of quick test on default gnome-terminal with ruler](docs/images/quick-test-gnome-terminal-ruler.png)

The rightmost block of face emoji should have skin tones applied, rather than shown in fallback mode as a tone swatch next to a yellow emoji, causing the line to overflow. Likewise, flags for ISO country codes are unsupported, while oddly region-coded flags are, and joined emoji (using ZWJ, the zero-width joiner) don't actually join.

Kitty does much better with emoji and handles facial skin tones properly. While country flags are supported, region flags aren't. Joined emoji are supported, though the spacing is increasingly off as they get more complex, and some joined emoji sequences don't join properly:

![Screenshot of quick test on Kitty with ruler](docs/images/quick-test-kitty-ruler.png)

While this is overall quite good, there are minor artifacts here and there: no bright bar on the basic colors, window frames that don't quite align, and slight shifting in a couple places on the corners, boxes, and compasses row.

Windows Terminal in Windows 10 similarly gets most of the pattern correct, but again fails on the emoji row:

![Screenshot of quick test on Windows Terminal in UTF-8 mode](docs/images/quick-test-windows-terminal-utf8.png)

Here it applies skin tones to the rightmost set, but still leaves extra room where the tone swatch *would* be, thus once again causing the line to be too long -- and this time also failing on the leftmost set of emoji faces, which should display in text outline mode as seen in the screenshot for `gnome-terminal`.

However, Windows Terminal will only do that well under Windows 10 if "beta" UTF-8 support is turned on (see separate [Windows 10](#Windows 10) section below). Without that, the test pattern will fall apart:

![Screenshot of quick test on Windows Terminal in UTF-16 mode](docs/images/quick-test-windows-terminal-default.png)

Some failures are more subtle, affecting only one or two features. Here's an example of the pattern as seen inside of GNU Screen in a `gnome-terminal`:

![Screenshot of quick test running inside GNU Screen on gnome-terminal](docs/images/quick-test-gnome-terminal-gnu-screen-ruler.png)

There are two new degradations here. The first is that GNU Screen supports 4-bit and 8-bit ANSI color, but not 24-bit ANSI color, so the red/green/blue bars in the top middle are missing. The second is that GNU Screen has replaced the italic attribute with inverse at the top left.

Operating system and terminal software versions can make a significant difference. For example, here's Terminal on macOS 10.14:

![Screenshot of quick test running on Terminal on macOS 10.14](docs/images/quick-test-macOS10.14-Terminal.png)

There's a massive improvement moving to Terminal on macOS 12.6:

![Screenshot of quick test running on Terminal on macOS 12.6](docs/images/quick-test-macOS12.6-Terminal.png)

And another overall quality improvement switching to iTerm2 on macOS:

![Screenshot of quick test running on iTerm2 on macOS](docs/images/quick-test-macOS-iterm2.png)

iTerm2 isn't purely an improvement over Terminal; there are a few minor degradations as well, such as shaded blocks being the wrong size, dashed lines being offset vertically, square corners being lengthened, and some text symbols gaining unrequested color.

Finally, some problems are merely configuration or option issues. Here's xterm in its default configuration on my Linux system, using the low-res (but at least somewhat Unicode-capable) **bitmap** "fixed" font, launched with just `xterm`:

![Screenshot of quick test running on xterm using the Unicode fixed font](docs/images/quick-test-xterm-fixed-unicode-ruler.png)

Many of the symbols are nearly unreadable, many of the advanced drawing characters are missing, and emoji aren't supported at all. Even worse, specifying a larger bitmap font size defaults to using the *non-Unicode* version of the font, here launched with `xterm -fn 10x20`:

![Screenshot of quick test running on xterm using the Latin-1 fixed font](docs/images/quick-test-xterm-fixed-latin1-ruler.png)

Using a scalable font will work better, even at the default small size, but color emoji are still unsupported (only text outlines are shown), and many of the advanced drawing characters are misaligned or cut off. Here I've just told `xterm` to use the default system monospace scalable font using `xterm -fa mono`:

![Screenshot of quick test running on xterm using the mono scalable font](docs/images/quick-test-xterm-mono-ruler.png)

Unsurprisingly the scalable font scales up better too (using `xterm -fa mono -fs 12`):

![Screenshot of quick test running on xterm using the mono scalable font at 12-point size](docs/images/quick-test-xterm-mono-12-ruler.png)

Full Terminal Test
------------------

The `terminal-test` program includes a far more complete set of test patterns across a range of categories, including descriptions of what you should expect to see in each pattern, as well as common artifacts that you should ideally *not* see. You can rate the display of each pattern on a simple scale, and the program will summarize the results in text or JSON (with the `--json` option) after you have rated the last test pattern.

Terminal-Specific Tweaks
------------------------

### Windows 10

By default Windows Terminal under Windows 10 supports only UTF-16, an old Unicode encoding that has otherwise been replaced by the UTF-8 encoding. To fix this, you'll need to follow the instructions in the [Enable UTF-8 in Windows Terminal](https://gist.github.com/sapeurfaire/91fe247cd9523971b8fab72d50df6c2a) gist, kindly provided by `sapeurfaire`.

AUTHOR
======

Geoffrey Broadwell <gjb@sonic.net>

COPYRIGHT AND LICENSE
=====================

Copyright © 2022-2025 Geoffrey Broadwell

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
