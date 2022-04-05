#SensorRUNv02

SensorRUNv02 is a MATLAB pipeline for analyzing biomechanics during running using inertial sensors. It is built on the RemoteBMX pipeline for biomechanical analysis (see below and at https://github.com/M-SenseResearchGroup/RemoteBMX). It is designed to analyze running data and segment it into steps and strides. It identifies foot contact events from shank and pelvis acceleration data. Review “About the RemoteBMX Pipeline” below to understand the general framework.


##Table of Contents
1. [Installation](#installation)
1. [Requirements](#requirements)
1. [Inputs] (#input)
1. [Outputs] (#outputs)
1. [What It Does] (#whatitdoes)
1. [Settings] (#settings)
1. [How to Run](#run)
1. [Worked Example] (#example)
1. [Modifying] (#modifying)
1. [About RemoteBMX] (#aboutremotebmx)

##Installation <a name="introduction"></a>
Download the SensorRUNv02 package, which includes a version of the RemoteBMX pipeline, “helpers” directory, and “sensorRUNv02_postanalysis” directory, and add to the MATLAB path.

##Requirements <a name="requirements"></a>
MATLAB version R2018a or later
MATLAB Signal Processing toolbox

##Inputs <a name="input"></a>

####Required
HDF 5 (.h5 extension) file containing data from APDM Opal MIMU sensors. 

The dataset should include unfiltered triaxial accelerations and rotational velocities and APDM-processed sensor orientations. The sensor set must include left shank, right shank, and sacrum. The file must contain at least one period of running to be analyzed. 

####Optional

Additional sensors may be included in the .h5 input file. These sensors can be named anything but best practice would be to follow these conventions:

* each sensor has a unique name
* sensors on the right side of the body have an upper or lower case R as the first character of their name.
* sensors on the left side of the body have an upper or lower case L as the first character of their name.
* sensors located on the midline (not right or left side of body) do NOT have upper or lower case R or L as the first character of their name


##Output <a name="output"></a>
A MATLAB structure called “session” that contains analysis results. Figures for quality control and review also are created and can be saved by user. See sensorRUNv02_outputs.txt for details on the "session" structure.


##What It Does <a name="whatitdoes"></a>

####Activity Identification
This step identifies segments of continuous running (referred to as “bouts”) within the dataset. Currently running bouts are identified by one of four methods, selected by the user:

* 'WholeTrial': use entire dataset, for example when running APDMs in streaming mode and starting and stopping trials from computer while participant is running.

* 'EventsStartStop': use APDM button event markers to identify start and stop of bouts. For example, when running sensors in logging mode and using sensor button event marker to indicate start and stop of different running conditions

* 'EventsStart': use APDM button event markers to identify start of bouts. Stop of bout is automatically set as *start + runDuration_s*. Same use case as 'EventsStartStop' except button events only used to indicate the start of a new running bout

* ‘ManualStartStop’: uses manual identification of bouts by user. User is given graph of whole trial and prompted to select start and stop. 

* 'ManualStart': same as ManualStartStop. Same as ManualStartStop except user only needs to select the start of each bout and the stop is automatically generated based on the duration specified in runDuration_s.

####Event Detection
The main event detected is foot contact. Foot contacts are identified from right/left shank and sacrum accelerometer data. It is assumed that the accelerometer data are time synchronized and the data contains only running data (no walking, jumping, standing, etc.). The algorithm follows closely that in ref [1] where right/left resultant shank accelerometer data are low pass filtered and peaks in this signal correspond to foot contact events. 

First, the dominant frequency of the resultant sacral acceleration trace is determined as a first estimate of the step frequency. The signals are then low passed at this frequency. This adaptive filtering approach was used in [2] and is different than the constant 5 hz cutoff frequency used in [1]. Peaks in the filtered sacral acceleration time series nicely isolate steps. The largest peak in the right and left filtered shank acceleration series between each of these sacral acceleration peaks are identified and the index of the largest is taken as the foot contact estimate.

####Analysis
This step takes use the foot contact events to do the following:

* compute the following spatiotemporal measures:
    * step time: right foot contact to left foot contact or vice versa
    * step frequency: inverse of step time
    * stride time: right foot contact to next right foot contact or vice versa
    * stride frequency: inverse of stride time
	*Note that since toe-off is not currently detected, contact time, flight time, and measures relying on these values are not currently calculated.

* estimate vertical displacement (excursion) of the center of mass from the movement of the sacrum-mounted IMU. 
    * algorithm: estimate vertical using pca technique [2]. Lowpass at estimated stride frequency [2]. Project onto estimated vertical. Demean and integrate to estimate velocity. Detrend and integrate again to estimate position. Then lowpass filter at 1 Hz. This last step (lowpass filtering) may be improved with adaptive cutoffs.This approach is similar to that used in [3].
	
* compute the peak shank resultant acceleration associated with foot contact.
    * shank impact acceleration looks for the largest acceleration in shank time series in a window of length specified by session.analysis.peakShankAccelWindow_s (in seconds, specified in project initialization) centered at the estimated foot contact.

* calculate user-defined aggregate statistics, such as mean and standard deviation, of these measures across all strides/steps, and for the right and left sides as defined by: session.analysis.aggregationFunctions and named as session.analysis.aggregationMethods.

#####References
[1] Mansour et al., 2015, Gait Posture, 42(4)
[2] Gurchiek et al., 2019, Sci Rep, 9(1)
[3] Gullstrand et al., 2009, Gait Posture, 30(1)

##User-Defined Settings <a name="settings"></a>

Settings for executing the project are set in the rbmxInitializeProject_sensorRUNv02.m file or via user input at prompts. See specific functions for additional info.

####activityIdentification 

* name: set in script; folder of activity identification scripts. Assumed to be housed within RemoteBMX/lib/S1_ActivityIdentification. 

* function: set in script; primary activity identification script. Used to read/parse data and identify bouts of running for subsequent event detection and analysis. Best practice is function = "rbmxActivityIdentification_name.m"

* method:  set in user prompts; method for determining start and stop of running bout(s)to analyze
    * Options:
        *'WholeTrial': use entire dataset, for example when running APDMs in streaming mode and starting and stopping trials from computer while participant is running.
        *'EventsStartStop': use APDM button event markers to identify start and stop of bouts. For example, when running sensors in logging mode and using sensor button event marker to indicate start and stop of different running conditions
        * 'EventsStart': use APDM button event markers to identify start of bouts. Stop of bout is automatically set as start + runDuration_s. Same use case as 'EventsStartStop' except button events only used to indicate the start of a new running condition
        * 'Manual': use graphical interface to select start (and stop) of bouts. If run_seconds is specified, the bout stops do not need to be selected. For example, when running in logging mode with no button events to mark start or end.
      
* runDuration_s: set in user prompts; seconds; duration for analysis following start of running bout. 
    * Options: 
         * 0: duration of each bout, end_bout_time = ...start_bout_time + runDuration_s
         * -1: not used 

####eventDetection 

* name: set in script; name folder containing event detection scripts. Assumed to be housed within RemoteBMX/lib/S2_EventDetection. 

* function: set in script; name of primary eventDetection script. Used to identify foot contacts during running in order to segment strides. Best practice is that function = "rbmxEventDetection_name.m"

* detectionAlgorithm: set in script; name of foot contact detection function 

####analysis  

* name: set in script; name of folder containing analysis scripts. Assumed to be housed within RemoteBMX/lib/S3_Analysis. 

* function: set in script; primary analysis script. Used to compute step and stride-related analyses and organize data for further post analyses. Best practice is function = "rbmxAnalysis_name.m"

* comExcursionAlgorithm: set in script; name of function to estimate center of mass vertical displacement. 

* peakShankAccelWindow_s: set in script; seconds; time window centered on foot contact used to search for maximum resultant shank acceleration. 0.2 seconds determined by trial-and-error.

* metrics: set in script; names of metrics to be computed for each step/stride. These will be used for headers in output reports and field names for outputs.

* aggregationMethods: set in script; names of statistical methods used for aggregating step/stride metrics. These will be used for headers in output reports and field names for outputs.

* aggregationFunctions: set in script; names of functions used to compute aggregate statistics. By default, aggregation functions are applied across all strides, right side only, and left side only. Required to match a built-in Matlab function (e.g., mean.m or std.m) or  custom function in the path (e.g., lib/helpers/cv.m to compute coefficient of variation). 


##How to Run <a name="run"></a>

1. In the MATLAB command window, type "RemoteBMX" and press "enter".

    ![ ] (images/RemoteBMXCall.png)

2. Select “sensorRUNv02” from the Project dropdown list. Note that this list will populate with all projectNames listed (as folder names rbmxProject_projectName) in the RemoteBMX/lib/S0_ProjectInitialization.

    ![ ] (images/SelectProject.png)

3. Click Ok in the Data File dialog box. Then select the input file containing the APDM sensor data from the file selector window that appears. This must be a .h5 file. See Input for file specifications. Only one file can be analyzed at a time.

    ![ ] (images/SelectApdmFile.png)

    ![ ] (images/SelectApdmFile2.png)

4. Select which method to use to segment running bouts. See the Activity Identification section for descriptions of the methods.

    ![ ] (images/SelectMethod.png)

5. For methods requiring a fixed running bout duration (Events Start and Manual Start), specify the analysis duration in seconds at the prompt. The default is 60 seconds.

    ![ ] (images/BoutDurationLength.png)

6. Select the APDM sensor for the left shank. Repeat for the right shank and sacrum.

    ![ ] (images/SelectLeftShank.png)

7. Review the graph of left and right shank resultant acceleration vs. time and indicate whether to proceed. This step provides an opportunity for a quality check of the data before proceeding. 

    ![ ] (images/QualityCheck1.png)

    This is a zoomed in version of the graph.

    ![ ] (images/QualityCheck2.png)

    Press any button to continue. 

    Select Continue on the prompt to continue the analysis. Selecting Quit will cancel execution of the pipeline.

    ![ ] (images/QualityCheck3.png)

    **Follow Steps 8-10 if using Manual method. For Events Methods, jump to Step 11.** 

8. Manually select Start (and Stop, if applicable) of bouts. 

    ![ ] (images/RunningBouts1.png)

    Using the same figure as in the previous step determine how many running bouts to analyze. Click Ok to access the figure. You can zoom and pan as needed on the figure to examine the data and determine how many sections of running data (bouts) to analyze. When ready to continue, press any key. 

9. Enter the number of running bouts to analyze. The default is 1.

    ![ ] (images/RunningBouts1.png)

10. Manually select start and stop times of each bout. 

    ![ ] (images/SelectStartStop.png)

    Click ok to continue. Use the zoom and pan functions to find the start of the first bout. The figure title will update to indicate which timepoints to select.

    Press any key to switch to crosshairs. Use the crosshairs to select the start time of the first bout. Note that the y-position of the cross-hairs does not matter. 

    The graph will revert back to Zoom and Pan so you can find the next time to select. 

    Start and Stops: If you are doing starts and stops, the next timepoint to select is the end of bout 1. After selecting the end of bout 1, proceed to selecting the start of bout 2, then the end of bout 2, etc. until the start and stops of all bouts have been identified.

    Start only: If you specified a bout duration, then you will only select the start time. The stop times will be automatically determined as the start time plus the bout duration (_stop_time_i = start_time_i + bout_duration_). The next timepoints to select is start of bout 2, then the start of bout 3, etc. until the starts of all bouts are selected.
    
    *Continue to Step 12*

11. **Only if using Events Start Stop or Events Start methods. Otherwise jump to Step 12.** 

    Select Ok in the dialog box. A figure will appear showing all the annotations in the .h5 file, the ID of the sensor that created them, and the time of the annotation in seconds relative to the start of the trial. Note that Sensor ID = 0 indicates it was annotated from the Motion Studio software.

    ![ ] (images/ApdmEvents1.png)

    ![ ] (images/ApdmEvents2.png)

    After reviewing the annotations, press any key to continue. A prompt will appear to select the annotations to use for the START of running bouts. Use CTRL/CMD to select multiple annotations. Click OK when done.

    ![ ] (images/EventsStart.png)

    For EventsStartStop, you will then be prompted to select the STOP annotations. 

    ![ ] (images/EventsStop.png)

12. The figure will populate with the start (o) and end (x) times of each running bout for verification.

    ![ ] (images/BoutVerify.png)

13. The analysis will run. Warnings will appear in the command window for any expected “steps” that did not have a clear right or left shank peak for identification. These will be consider invalid steps. 

    Note that the algorithm will find "steps" in non-gait data. Carefully review and re-run the analysis if non-gait data is accidentally included in the activity identification step.

    ![ ] (images/FootContactError.png)

14. A graph of all identified foot contacts will appear for quality control. There will be one graph for each running bout. 

    It shows the raw (unfiltered) right shank (red), left shank (green), and sacrum (black) vector magnitude acceleration traces that were fed to the algo. It also shows the low-pass filtered accelerations that were used to detect foot contact (raw = solid line, filtered = dashed). 

    Overlaid on the filtered shank traces are o’s to indicate the start of a step and x’s to indicate the end of a step. o’s/x's on the right shank trace indicate right steps, while o’s/x’s on the left shank indicate left steps.

    ![ ] (images/FootContact1.png)
    
    Zoomed in you can see the identified foot contacts for a series of steps:

    ![ ] (images/FootContact2.png)


15. Click Yes or No to save a .mat file of the analysis results. The output, a structure called “session,” will remain available in the workspace regardless of selection. All created figures also will remain available for review or saving.

    ![ ] (images/SaveMat1.png)

    If you select yes, a folder selector box will appear. Select the folder to save the output .mat.

    ![ ] (images/SaveMat2.png)

    Then enter the name for the .mat file. By default the .mat file is named “analysis_currentDate_inputFileName”. The output is structure called “session” and is also available in the MATLAB workspace for subsequent analyses.

    ![ ] (images/SaveMat3.png)


##Worked Examples <a name="example"></a>
Worked Example 1 - using APDM event markers ...IN PROGRESS
Worked Example 2 - using graphical selection ...IN PROGRESS

##Modifying <a name="modifying"></a>
To make a modificaation to the sensorRUNv02 pipeline, copy the sensorRUNv02 pipeline and rename it "NewProject", and then make modifications to the copied code as follows:  

First, go to RemoteBMX/lib/SO_ProjectInitialization and duplicate the folder rbmxProject_sensorRUNv02.Rename the copied folder to rbmxProject_NewProject, keeping it in the S0_ProjectInitialization folder.

In the new rbmxProject_NewProject folder, rename rbmxInitializeProject_sensorRUNv02.m to rbmxInitializeProject_NewProject. Open the file and begin making edits. Remember to rename the function name in the first line to match the filename. For example,

    function [session] = rbmxInitializeProject_sensorRUNv02(session) 

should be

    function [session] = rbmxInitializeProject_NewProject(session) 

Repeat these same steps for the other folders in the RemoteBMX pipeline. Replace all instances of sensorRUNv02 with "NewProject". Be sure to update the calls to these functions accordingly in the rbmxInitializeProject... m-file and all other scripts. The following folders should be copied, renamed, and updated:

* S1_ActivityIdentification/sensorRUNv02_SupervisedRunID_imu3
* S2_EventDetection/sensorRUNv02_FootContactID_imu3_v01
* S3_Analysis/sensorRUNv02_RunAnalysis_imu3_v02

See “About the RemoteBMX Pipeline” below for naming conventions and other critical information.


##About the RemoteBMX Pipeline <a name="aboutremotebmx"></a>

Learn more and see other applications at: [https://github.com/gurchiek/RemoteBMX] (https://github.com/gurchiek/RemoteBMX)

Script: RemoteBMX
Author: Reed Gurchiek, June 2019

####Summary
RemoteBMX is a pipeline for biomechanical analysis of human movement in remote environments (i.e. daily life). There are three basic steps: (1) activity identification: activities being evaluated are identified from wearable sensor data (e.g. walking), (2) event detection: task specific events are identified that may be useful for further analysis (e.g. foot contact and foot off events during walking), and (3) analysis: the various signals from the wearable sensors are processed to compute informative descriptors of the identified tasks. RemoteBMX requires MATLAB version R2018a or later.

####How to use
An example application of RemoteBMX is monitoring a patient’s gait following surgery. This application is available upon downloading the RemoteBMX package. An example dataset for this application is available at: https://www.uvm.edu/~rsmcginn/lab.html. The first step in designing a new application is to create a project. Project’s are given a name (e.g. projectName) and consist of a directory within RemoteBMX/lib/S0_ProjectInitialization which must be named ‘rbmxProject_projectName’ within which contain project specific functions/files for initiating the project, one of which must be a function named ‘rbmxInitializeProject_projectName’. The example project is titled ‘ACLR19’.

The ‘rbmxInitializeProject_projectName’ function initializes a ‘session’ MATLAB struct which specifies which activity identifier to use, which event detector to use, which analysis function to use, function specific parameters, and contains imported patient specific data. IMPORTANT: the way data is imported and structured in the MATLAB environment must be compatible with all functions used in the pipeline. All rbmx* functions should accept the ‘session’ struct as input and output the same ‘session’ struct with updated fields.

Activity identifiers consist of a directory within RemoteBMX/lib/S1_ActivityIdentification/ which is given a name ‘activityIdentifierName’ within which contain identifier specific functions/files for activity identification, one of which must be a function named ‘rbmxActivityIdentification_activityIdentifierName’. The example activity identifier is titled ‘ACLR19_WalkClassification_v01’ and is accompanied by the .mat file ‘Classifier_ACLR19_WalkClassification_RBFSVM_db2_cornerDistance.mat’.

Event detectors consist of a directory within RemoteBMX/lib/S2_EventDetection/ which is given a name ‘eventDetectorName’ within which contain detector specific functions/files for event detection, one of which must be a function named ‘rbmxEventDetection_eventDetectorName’. The example event detector is ‘ACLR19_StrideDetectionSegmentation_v01’ and is accompanied by the MATLAB function ‘getGaitEvents_ccThighAccelerometer.m’.

Analyzers consist of a directory within RemoteBMX/lib/S3_Analysis/ which is given a name ‘analysisName’ within which contain analyzer specific functions/files for analysis, one of which must be a function named ‘rbmxAnalysis_analysisName’. The example analysis is ‘ACLR19_AsymmetryAnalysis_v01’.

To use the example application, download the RemoteBMX package and the M-Sense Research Group ActivityIdentification package (https://github.com/M-SenseResearchGroup/ActivityIdentification) and add them to the MATLAB path. Download example dataset: https://www.uvm.edu/~rsmcginn/lab.html. In the MATLAB command window, type ‘RemoteBMX’ and press ‘enter’.

####Reference
Gurchiek, R.D., Choquette, R.H., Beynnon, B.D. et al. Open-Source Remote Gait Analysis: A Post-Surgery Patient Monitoring Application. Sci Rep 9, 17966 (2019). https://doi.org/10.1038/s41598-019-54399-1






