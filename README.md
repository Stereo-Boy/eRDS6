
-------------------------------------------------------------------------------------------------------------------
						#eRDS6
-------------------------------------------------------------------------------------------------------------------

eRDS (version 6) is a program to precisely measure stereoscopic vision performance using recommendations from 
Chopin et al., 2019, OPO & Scientific Reports. Indeed, it uses a dynamic RDS to prevent monocular cues and a depth
ordering task rather than an oddball to avoid binocular non-stereo cues. It is a depth detection task, and it 
issues a threshold separately for crossed (close) and uncrossed (far) disparities. Short presentations (200ms) 
allows to separate for these two measures (otherwise eye movements can inverse the sign of disparities).
Long presentations (2 sec) allows for a better threshold using vergence and eye movements.  Stimulus are two
identical rectangular surface-RDS (strips) around a third one with a frame around and a fixation cross in the center. 
Dots are white and black, or blue and black. Either the strip with the blue dots or the one with the white dots
is in front of the others and the task is to indicate whether the blue is in front or behind (2AFC).
Instead of a constant stimuli paradigm, we use an adaptation of Psi (Kontsevich & Tyler, 1999) bayesian algorithm 
adapted to non-monotonic psychometric functions. Indeed, we also use marginalization of nuisance parameters following 
Prins (2013). The function underlied in the Psi estimation is a non-monotonic adaptation of the logistic function defined 
by Serrano-Pedraza et al., 2016 (IOVS) and Garcia-Pérez (1998). Prior is estimated from 24 practice trials, and 10 
additionnal practice trials are run (and discarded) simply to learn the task. The program involves to first run the 
DST test to calibrate the stereoscope appropriately and ensure fusion. 

The function needs the DST8 program (https://github.com/Stereo-Boy/DST8.git) and the Psychtoolbox and the programs
required to run that toolbox (e.g. gstreamer), see on http://psychtoolbox.org/download.html

