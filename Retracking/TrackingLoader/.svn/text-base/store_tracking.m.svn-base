% Store the tracking data for an experiment.

function [result] = store_tracking(sage_params_path, experiment_dir_path)
    % TODO: doc
    
    try
        if nargin == 0
            if isdeployed
                fprintf(2, 'Usage: store_experiment <path to SAGE params file> <path to box data folder>\n\nSAGE params file should contain:\n\nhost: <host name>\ndatabase: <database name>\nusername: <user name>\npassword: <password>')
            else
                error('No parameters supplied.');
            end
            result = 2;
            return;
        end
        
        warning off MATLAB:javaclasspath:jarAlreadySpecified
        
        %% Make sure the MySQL client JAR can be found.
        classpath = getenv('CLASSPATH');
        for path = regexp(classpath, ':', 'split')
            javaaddpath(path);
        end

        %% Connect to SAGE
        fid = fopen(sage_params_path);
        try
            params = strtrim(textscan(fid, '%s %s'));
            host = params{2}{strmatch('host:', params{1})};
            db_name = params{2}{strmatch('database:', params{1})};
            user_name = params{2}{strmatch('username:', params{1})};
            password = params{2}{strmatch('password:', params{1})};
            fclose(fid);
        catch ME
            fclose(fid);
            rethrow(ME);
        end
        db = database(db_name, user_name, password, 'com.mysql.jdbc.Driver', ['jdbc:mysql://' host '/' db_name]);
        
        if ~isempty(db.Message)
            if strcmp(db.Message, 'JDBC Driver Error: com.mysql.jdbc.Driver. Driver Not Found/Loaded.')
                message = [db.Message char(10) char(10) 'Make sure you the path to the MySQL Connector JAR file is in the CLASSPATH.'];
            else
                message = db.Message;
            end
            error(['Could not create database connection: ' message]);
        end
        % Make sure the experiment is loaded atomically.
        set(db, 'AutoCommit', 'off');

        %% Wrap everything else in an exception handler so that the DB connection is guaranteed to be closed.
        try
            [parent_dir, experiment_name, dir_ext, dir_version] = fileparts(experiment_dir_path); %#ok
        
            % The directory will never have an extension or version so put the pieces back together. (BOXPIPE-70)
            experiment_name = [experiment_name dir_ext dir_version];

            %% Make sure the experiment has already been loaded.
            curs = exec(db, ['select id from experiment where name = ''' experiment_name '''']);
            curs = fetch(curs);
            if strcmp(curs.Data{1}, 'No Data')
                error('Experiment ''%s'' is not in SAGE.  Please use store_experiment to load it.', experiment_name);
            else
                experiment_id = curs.Data{1};
            end
            close(curs)

            %% Load the experiment parameters.
            data = load(fullfile(experiment_dir_path, [experiment_name '.exp']), '-mat');
            source = data.experiment.actionsource(1);
            protocol = data.experiment.actionlist(1, source).name;

            %% Lookup the session (tube) ID's.
            curs = exec(db, ['select id, name from session where type_id = ' cv_term('region') ' and experiment_id = ' num2str(experiment_id)] );
            curs = fetch(curs);
            if strcmp(curs.Data{1}, 'No Data')
                error('No sessions exist for experiment %s.', experiment_name);
            else
                session_ids_names = curs.Data;
                session_count = length(curs.Data);
            end
            close(curs);

            %% Loop through each temperature.
            for source = data.experiment.actionsource
                temperature = data.experiment.actionlist(1, source).T;
                sub_dir_name = sprintf('%02d_%s_%d', source, protocol, temperature);

                %% Lookup the phase (sequence) ID's for this temperature.
                curs = exec(db, ['select id, name from phase where experiment_id = ' num2str(experiment_id) ' and type_id = ' cv_term(['sequence_' num2str(temperature)])]);
                curs = fetch(curs);
                if strcmp(curs.Data{1}, 'No Data')
                    error('No phases exist at %d degrees for experiment %s.', temperature, experiment_name);
                else
                    phase_ids_names = curs.Data;
                    phase_count = length(curs.Data);
                end
                close(curs);

                %% Loop through the possible sequence numbers and see if they exist on disk.
                for phase_num = 1:phase_count
                    [phase_id, phase_name] = phase_ids_names{phase_num,:};

                    for session_num = 1:session_count
                        [session_id, session_name] = session_ids_names{session_num, :};

                        %% Make sure the analysis_info hasn't already been loaded.
                        curs = exec(db, ['select count(id) from score_array where session_id = ' num2str(session_id) ' and phase_id = ' num2str(phase_id)]);
                        curs = fetch(curs);
                        score_count = curs.Data{1};
                        close(curs)
                        
                        if score_count == 0
                            tube_name = sprintf('%02d_%s_seq%s_tube%s', source, protocol, phase_name, session_name);
                            analysis_path = fullfile(experiment_dir_path, 'Output', sub_dir_name, tube_name, 'analysis_info.mat');    %#ok
                            try
                                load(analysis_path, 'analysis_info');

                                if ~exist('analysis_info', 'var')
                                    error('No analysis_info structure was found.')
                                else
                                    fields = fieldnames(analysis_info);
                                    for field_num = 1:length(fields)
                                        field_name = fields{field_num};
                                        if isfloat(analysis_info.(field_name)) && any(strcmp(field_name, {'tracked_num', 'moving_num', 'start_move_num', 'pos_hist', 'move_pos_hist', 'max_tracked_num', 'index'}))
                                            % These fields are actually int values even though they are in double matrices.  Convert to save a lot of space.
                                            [encoded_data, data_type] = SAGE.DataSet.encodeData(int16(analysis_info.(field_name))); %#ok
                                        else
                                            [encoded_data, data_type] = SAGE.DataSet.encodeData(analysis_info.(field_name), 'half'); %#ok
                                        end
                                        [rows, cols] = size(analysis_info.(field_name));
                                        curs = exec(db, ['insert into score_array (session_id, phase_id, term_id, type_id, data_type, row_count, column_count, value) values (' num2str(session_id) ', ' ...
                                                                                                                                                                                num2str(phase_id) ', ' ...
                                                                                                                                                                                cv_term('not_applicable') ', ' ...
                                                                                                                                                                                cv_term(['analysis_info.' field_name]) ', ' ...
                                                                                                                                                                                '''' data_type ''', ' ...
                                                                                                                                                                                num2str(rows) ', ' ...
                                                                                                                                                                                num2str(cols) ', ' ...
                                                                                                                                                                                'compress(''' encoded_data '''))']);
                                        if ~isempty(curs.Message)
                                            error(['Could not add score for phase #' num2str(phase_id) '/ session #' num2str(session_id) ': ' curs.Message]);
                                        end
                                        close(curs);
                                        % clear encoded_data ?
                                    end

                                    clear analysis_info
                                end
                            catch ME
                                display(['Could not store tracking for ' tube_name ' (' ME.message ')'])
                            end
                        end
                    end
                end
            end

            %% Commit the entire experiment.
            commit(db);
            close(db);
        
            result = 0;
        catch ME
            rollback(db);
            close(db);
            rethrow(ME);
        end
    catch ME
        result = 1;
        rethrow(ME);
    end
end
    
function term_lookup = cv_term(term_name)
    term_lookup = ['getCvTermId(''fly_olympiad_box'', ''' term_name ''', NULL)'];
end
