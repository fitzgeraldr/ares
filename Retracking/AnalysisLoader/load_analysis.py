import sage
import scipy.io
import os.path, sys


# The list of fields to load for each sequence.  The fields that are duplicates of the analysis_info data have been filtered out.
fields = {}
fields[1.4] = {}
fields[1.4][1] = ['mov_frac', 'med_vel', 'Q3_vel', 'tracked_num']
fields[1.4][2] = ['peak_mov_frac', 'peak_med_vel', 'long_after_med_vel', 'baseline_mov_frac', 'baseline_med_vel', 'startle_resp', 'tracked_num', 'average_ts_med_vel']
fields[1.4][3] = ['tracked_num', 'mean_motion_resp', 'std_motion_resp', 'motion_resp_diff']
fields[1.4][4] = ['Side_diff', 'tracked_num', 'med_vel_X', 'med_disp_X', 'disp_max', 'disp_rise']
fields[1.4][5] = ['Side_diff', 'tracked_num', 'med_vel_X', 'med_disp_X', 'disp_end', 'disp_peak', 'disp_peak_SE']
fields[1.5] = {}
fields[1.5][1] = ['mov_frac', 'max_mov_frac', 'med_vel', 'max_vel', 'Q3_vel', 'tracked_num', 'max_tracked_num', 'min_tracked_num']
fields[1.5][2] = fields[1.5][1] + ['peak_mov_frac', 'peak_med_vel', 'long_after_med_vel', 'baseline_mov_frac', 'baseline_med_vel', 'startle_resp', 'average_ts_med_vel']
fields[1.5][3] = fields[1.5][1] + ['mean_motion_resp', 'std_motion_resp', 'motion_resp_diff']
fields[1.5][4] = fields[1.5][1] + ['Side_diff', 'med_vel_x', 'med_disp_x', 'disp_max', 'disp_rise', 'disp_norm_max']
fields[1.5][5] = fields[1.5][1] + ['Side_diff', 'med_vel_x', 'med_disp_x', 'disp_end', 'disp_peak', 'disp_peak_SE', 'UVG_pref_diff', 'UVG_cross']

# The list of plots generated.
plots = {}
plots[1.5] = ['comparison_summary']
tempPlots = {}
tempPlots[1.5] = ['seq2_median_velocity_averaged', 'seq2_median_velocity', 'seq3_LinMotion_median_x_velocity_&_average', 'seq4_avg_vel_disp', 'seq4_median_velocity_x&PI', 'seq5_avg_vel_disp', 'seq5_median_velocity_x&PI']

analysisVersion = None

experimentPath = sys.argv[2]
experimentName = os.path.basename(experimentPath)

try:
    # Make sure the directory really exists.
    if not os.path.exists(experimentPath):
        raise IOError, 'No experiment directory found at ' + experimentPath
    
    db = sage.Connection(paramsPath = sys.argv[1])
    cv = sage.CV('fly_olympiad_box')
    olympiadLab = sage.Lab('olympiad')
    
    # Make sure the experiment exists in SAGE.
    experiments = db.findExperiments(name = experimentName, typeTerm = cv.term('box'), lab = olympiadLab)
    if len(experiments) == 0:
        raise ValueError, 'Could not find the \'' + experimentName + '\' experiment in SAGE.' 
    experiment = experiments[0]
    
    imageFamily = sage.ImageFamily(db, 'fly_olympiad_box', 'http://img.int.janelia.org/flyolympiad-data/fly_olympiad_box/', '/groups/sciserv/flyolympiad/Olympiad_Screen/box/box_data/', olympiadLab)
    
    # Check which images have been linked.
    images = imageFamily.findImages(experiment)
    avisLinked = False
    sbfmfsLinked = False
    for image in images:
        if image.name.endswith('.avi'):
            avisLinked = True
        elif image.name.endswith('.sbfmf'):
            sbfmfsLinked = True
    
    # Get the list of temperature sub-folders from the top-level .exp file (which is really a .mat file)
    expPath = os.path.join(experimentPath, experimentName + '.exp')
    mat = scipy.io.loadmat(expPath, struct_as_record = True)
    actionList = mat['experiment']['actionlist'][0, 0]
    actionSource = mat['experiment']['actionsource'][0, 0][0]
    tempCount = actionSource.shape[0]
    
    # Keep track of whether all tubes are running the same line.
    commonLine = None
    
    for tempIndex in actionSource:
        action = actionList[0,tempIndex - 1]
        protocol = action['name'][0]
        temp = action['T'][0,0]
        
        tempPrefix = '%02d_%s_%02d' % (tempIndex, protocol, temp)
        shortTempPrefix = '%02d_%s' % (tempIndex, protocol)
        
        # Make sure the analysis results file is there.
        analysisPath = os.path.join(experimentPath, 'Output', tempPrefix + '_analysis_results.mat')
        if not os.path.exists(analysisPath):
            raise IOError, 'No analysis results file found at ' + analysisPath
        
        # Load the file and make sure the analysis_results field is present.
        mat = scipy.io.loadmat(analysisPath, struct_as_record = True)
        if 'analysis_results' not in mat:
            raise ValueError, 'No analysis_results field found in the analysis results file.'
        analysisResults = mat['analysis_results']
        
        for tubeNum in range(1, 7):
            tubeAnalysis = analysisResults[0, tubeNum - 1]
            
            if tubeAnalysis['analysis_version'].size > 0:
                analysisVersion = tubeAnalysis['analysis_version'][0,0]
                if not analysisVersion in fields or not analysisVersion in plots or not analysisVersion in tempPlots:
                    raise ValueError, 'Unknown analysis version: ' + str(analysisVersion)
            if analysisVersion is None:
                raise ValueError, 'Could not determine analysis version.'
            
            # Look up the session so we know which line was in the tube.
            sessions = experiment.findSessions(name = str(tubeNum), typeTerm = cv.term('region'))
            if len(sessions) != 1:
                raise ValueError, 'Could not find the session for tube ' + str(tubeNum) + ' of experiment ' + experimentName
            tubeLine = sessions[0].line
            
            if commonLine is None:
                commonLine = tubeLine
            elif commonLine != tubeLine:
                commonLine = False
            
            for seqNum in range(1, 6):
                # Create an "analysis" session.
                session = experiment.createSession('Analysis %s for tube %s, sequence %s @ %s degrees' % (analysisVersion, tubeNum, seqNum, temp), cv.term('analysis'), tubeLine, olympiadLab)
                session.setProperty(cv.term('version'), analysisVersion)
                session.setProperty(cv.term('region'), tubeNum)
                session.setProperty(cv.term('sequence'), seqNum)
                session.setProperty(cv.term('temperature'), temp)
                
                # Attach the score arrays to the session.
                seqStruct = tubeAnalysis['seq' + str(seqNum)]
                for fieldName in fields[analysisVersion][seqNum]:
                    matrix = seqStruct[fieldName][0,0]
                    session.storeScoreArray(cv.term(fieldName), matrix, dataType = 'half')
                
                if not sbfmfsLinked:
                    # Store links to the SBFMF files.
                    sbfmfPath = '%s/%s/%s_tube%d_sbfmf/%s_seq%d_tube%d.sbfmf' % (experimentName, tempPrefix, shortTempPrefix, tubeNum, shortTempPrefix, seqNum, tubeNum)
                    imageFamily.addImage(sbfmfPath, experiment = experiment, line = tubeLine, creator = 'Box Pipeline', imageType = 'tube_sequence_movie')
        
        if analysisVersion is not None:
            # Store links to the temperature specific plots.
            for plotName in tempPlots[analysisVersion]:
                imageFamily.addImage(experimentName + '/Output/' + tempPrefix + '_' + plotName + '.pdf', experiment = experiment, line = None if commonLine == False else commonLine, creator = 'Box Pipeline', imageType = plotName)
                imageFamily.addImage(experimentName + '/Output/' + tempPrefix + '_' + plotName + '.png', experiment = experiment, line = None if commonLine == False else commonLine, creator = 'Box Pipeline', imageType = plotName)
        
        if not avisLinked:
            # Store links to the sequence AVI's.
            for seqNum in range(1, 6):
                aviPath = '%s/%s/%s_seq%d.avi' % (experimentName, tempPrefix, shortTempPrefix, seqNum)
                imageFamily.addImage(aviPath, experiment = experiment, line = tubeLine, creator = 'Box Pipeline', imageType = 'box_sequence_movie')
           
    if analysisVersion is not None:
        # Store links to the global plots.
        for plotName in plots[analysisVersion]:
            imageFamily.addImage(experimentName + '/Output/' + plotName + '.pdf', experiment = experiment, line = None if commonLine == False else commonLine, creator = 'Box Pipeline', imageType = 'comparison_summary_plot')
            imageFamily.addImage(experimentName + '/Output/' + plotName + '.png', experiment = experiment, line = None if commonLine == False else commonLine, creator = 'Box Pipeline', imageType = 'comparison_summary_plot')
    
    db.commitChanges()
    print experimentName + ' loaded successfully.'
except:
    (exceptionType, exceptionValue, exceptionTraceback) = sys.exc_info()
    print experimentName + ' failed to load: ' + str(exceptionValue)
    raise
