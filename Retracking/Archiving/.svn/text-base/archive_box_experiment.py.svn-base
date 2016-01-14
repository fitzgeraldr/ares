# 

import sage
import os.path, sys, shutil, glob

if len(sys.argv) < 3:
    print 'Usage:\n\tarchive_box_experiment <SAGE config file path> <experiment path>'
    sys.exit(-1)

experimentPath = sys.argv[2]
experimentName = os.path.basename(experimentPath)

try:
    # Make sure the directory really exists.
    if not os.path.exists(experimentPath):
        raise IOError, 'No experiment directory found at ' + experimentPath
    
    db = sage.Connection(paramsPath = sys.argv[1])
    flyCV = sage.CV('fly')
    boxCV = sage.CV('fly_olympiad_box')
    qcCV = sage.CV('fly_olympiad_qc')
    olympiadLab = sage.Lab('olympiad')
    
    # Make sure the experiment exists in SAGE.
    experiments = db.findExperiments(name = experimentName, typeTerm = boxCV.term('box'), lab = olympiadLab)
    if len(experiments) == 0:
        raise ValueError, 'Could not find the \'' + experimentName + '\' experiment in SAGE.' 
    experiment = experiments[0]
    
    # Don't archive if there was some kind of error
    if experiment.getProperty(qcCV.term('automated_pf')) != 'P' or \
       experiment.getProperty(qcCV.term('manual_pf')) == 'F' or \
       not os.path.exists(os.path.join(experimentPath, 'Output', 'comparison_summary.pdf')):
        print 'Experiment was not successful, no archiving will be done.'
    else:
        archiveBehavior = experiment.getProperty(flyCV.term('archive_behavior'))
        if archiveBehavior is None or archiveBehavior == 'default':
            pass
        else:
            # The experiment should be archived.
            archiveDir = experiment.getProperty(flyCV.term('archive_path'))
            if not os.path.exists(archiveDir):
                raise ValueError, 'Could not find the archive location for \'' + experimentName + '\''
            
            destPath = os.path.join(archiveDir, experimentName)
            
            if archiveBehavior == 'move':
                # Move the experiment to the non-Olympiad archive space
                print 'Moving \'' + experimentName + '\' to ' + archiveDir + '...'
                shutil.move(experimentPath, archiveDir)
                os.symlink(destPath, experimentPath)
            elif archiveBehavior == 'copy':
                # Copy the experiment to the non-Olympiad archive space.
                # Make sure to resolve sym. links so the content isn't lost.
                # (In one shell test this took 4.5 minutes.)
                print 'Copying \'' + experimentName + '\' to ' + archiveDir + '...'
                shutil.copytree(experimentPath, destPath, symlinks = True)
            elif archiveBehavior == 'copy_and_remove_sbfmf':
                print 'Copying \'' + experimentName + '\' to ' + archiveDir + '...'
                shutil.copytree(experimentPath, destPath, symlinks = True)
                print 'Removing SBFMF\'s...'
                sbfmfPaths = glob.glob(os.path.join(experimentPath, '*', '*_sbfmf'))
                for sbfmfPath in sbfmfPaths:
                    shutil.rmtree(sbfmfPath)
            else:
                raise ValueError, 'Unknown behavior action: ' + archiveBehavior
        
        print '\'' + experimentName + '\' archiving complete.'
except:
    (exceptionType, exceptionValue, exceptionTraceback) = sys.exc_info()
    print experimentName + ' failed to archive: ' + str(exceptionValue)
    raise
