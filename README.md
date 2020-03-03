
-------------------------------------------------------------------------------------------------------------------
						#eRDS6
-------------------------------------------------------------------------------------------------------------------

eRDS (version 6) is a program to precisely measure stereoscopic vision performance using recommendations from 
Chopin et al., 2019, OPO & Scientific Reports. Indeed, it uses a dynamic RDS to prevent monocular cues and a depth
ordering task rather than an oddball to avoid binocular non-stereo cues. It is a depth detection task, and it 
issues a threshold separately for crossed (close) and uncrossed (far) disparities. Short presentations (200ms) 
allows to separate for these two measures (otherwise eye movements can inverse the sign of disparities).
Long presentations (2 sec) allows for a better threshold using vergence and eye movements.  Stimulus are two 
identical rectangular surface-RDS with a frame around and a fixation cross in the center. Dots are white and black.
Either the left or the right surface is in front of the other and the task is to indicate which one (2AFC).
Instead of a constant stimuli paradigm, we use an adaptation of Psi (Kontsevich & Tyler, 1999) bayesian algorithm 
to non-monotonic psychometric functions. Indeed, we also use marginalization of nuisance parameters following 
Prins (2013). Prior is estimated from 25 practice trials, and 10 additionnal practice trials are run 
(and discarded) simply to learn the task. The program involves to first run the DST test to calibrate the
stereoscope appropriately and ensure fusion.

The function needs the DST8 program (https://github.com/Stereo-Boy/DST8.git) and the Psychtoolbox and the programs
 required to run that toolbox (e.g. gstreamer), see on http://psychtoolbox.org/download.html

