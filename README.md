
-------------------------------------------------------------------------------------------------------------------
						#eRDS6
-------------------------------------------------------------------------------------------------------------------

##What is eRDS?
eRDS (version 6) is a program to precisely measure stereoscopic vision performance using recommendations from 
Chopin et al., 2019, OPO & Scientific Reports. Indeed, it uses a dynamic RDS to prevent monocular cues and a
depth ordering task rather than an oddball to avoid binocular non-stereo cues. It is a depth detection task, 
and it issues a threshold separately for crossed (close) and uncrossed (far) disparities.
Short presentations (200ms) allows to separate for these two measures (otherwise eye movements can inverse the 
sign of disparities). Long presentations (2 sec) allows for a better threshold using vergence and eye movements. 
Stimulus are three identical rectangular surface-RDS (stripes) with a frame around and a fixation cross in the 
center. Dots are white and black or blue and black.
Either the central or the outer stripes are in front of the others and the task is to indicate whether the blue 
dots surface is closer or further (2AFC).
Instead of a constant stimuli paradigm, we use an adaptation of Psi (Kontsevich & Tyler, 1999) bayesian algorithm
adapted to non-monotonic psychometric functions. Indeed, we also use marginalization of nuisance parameters following
Prins (2013) and implement the adaptive searchgrid rescaling from Doire et al. (2017) for threshold parameter.
Prior is uniform but estimated from 12 practice trials, and we recommend to first run 10 additionnal practice trials 
(that will be discarded).
The program involves to first run the DST test to calibrate the stereoscope appropriately and ensure fusion.

##What do I first need to do to install the program and material?
The function needs the DST8 program (https://github.com/Stereo-Boy/DST8.git) and the Psychtoolbox and the programs
required to run that toolbox (e.g. gstreamer), see on http://psychtoolbox.org/download.html

You need a mirror stereoscope.

You need to enter your screen settings in the screen_parameters.m file in screen folder.

##How do I run a participant?
See walkthrough and participant's instructions in Walkthrough and Instructions folder.

##How do I analyze the data?
It is also described in the walkthrough but analysis code is analysis folder and figures are saved automatically 
in the figures folder.

