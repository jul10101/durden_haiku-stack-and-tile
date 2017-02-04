---
layout: default
---

The <i>durden/tools</i> source folder is scanned for scripts on startup.
Anything in this folder can be removed safely without loss of any critical
functions, and are provided as a means for extending durden features in
a way similar to [Widgets](widgets), but with a more generic focus as they
can introduce both visible and non-visibile behavior and are not confined
to the menu HUD.

The example tools that have been included in the source distribution
are: [Model Viewer](#model), [Dropdown Terminal](#dropdown) and the
[Autolayouter](autolay).

# Dropdown Terminal <a name="dropdown"/>

The dropdown terminal is both a convenience- terminal that can be reached
regardless of workspace layout mode (though be careful with the dedicated
fullscreen mode as it can spawn, but won't be visible).

<center><a href="images/dropdown.png">
	<img alt="dropdown terminal" src="images/dropdown.png" style="width: 50%"/>
</a></center>

It is also a [safety/security](security) feature (see that page for more
detail), and deliberately avoids sharing settings with the normal
[terminal](terminal). It also introduces these additional settings:

- Width: percentage of active display width to allocate
- Height: percentage of active display height to allocate

Its settings are registered on the path
<i>global/config/tools/dropdown terminal</i> and the terminal itself is
activated via the <i>global/tools/dropdown terminal</i> path. To be efficient,
it should be bound to a keyboard combination.

Also make sure that the lock toggle setting (<i>input/keyboard/lock toggle</i>)
is set to meta1 or meta2 as the 'double tap to unlock' feature is used to hide
the terminal - or the terminal will refuse to activate.

# Model Viewer <a name="model"/>
This was added more for the 'demo' effect rather than much serious effort, and
relies on an old and ugly model format, scanned in the <i>durden/models</i>
directory. The README file in that directory also tells where you can download
some example modules.

<center><a href="images/model.png">
	<img alt="model viewer" src="images/model.png" style="width: 50%"/>
</a></center>

The tool adds a <i>global/tools/modelviewer</i> path for browsing/launching
models. It also adds the target window paths <i>target/source</i> and
<i>target/view</i>.

Clicking/dragging with the mouse in a model window either moves the camera
or rotates the model (TAB symbol switches between these two states).

The <i>target/source</i> path specifices which window that other input events
will be forwarded to, and what data source should be added to the display-
portion of a model.

The <i>target/view</i> switches between two predefined viewing positions/angles.

# Future Changes
- On-screen Keyboard
- Touchpad Configuration