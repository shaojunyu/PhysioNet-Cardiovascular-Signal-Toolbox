function [rr,t] = Analyze_ABP_PPG_Waveforms(Waveform,Type,HRVparams,detectedQRS,subjectID)
%
%   Analyze_ABP_PPG_Waveforms(Waveform,Type,HRVparams,detectedQRS,subjectID)
%	OVERVIEW:
%       Analyze ABP or PPG waveform 
%
%   INPUT:
%       Waveform    - matrix containing the a raw signal in each column
%       Type        - array containing the signal type of waveforms in each column: 
%                     'APB' for ABP waveform 
%                     'PPG' for PPG waveform
%       HRVparams   - struct of settings for HRV analysis  
%       subjectID   - string to identify current subject
%
%   OUTPUT
%       Annotation files
%
%   Written by Giulia Da Poian (giulia.dap@gmail.com) on Sep 6, 2017.


NmbOfSigs = size(Waveform,2);
AnnotationFolder = strcat(HRVparams.writedata, filesep, 'Annotation', filesep);
if ~exist(AnnotationFolder, 'dir')
   mkdir(AnnotationFolder)
end
addpath(AnnotationFolder)

rr = [];
t = [];

for i = 1:NmbOfSigs
    
    current_type = Type{i};
    switch current_type
        case 'PPG'
            % PPG Detection - qppg
            [PPGann] = qppg(Waveform(:,i),HRVparams.Fs);
            % PPG SQI 
            [ppgsqi,ppgsqiMatrix,~,~] = PPG_SQI_buf(Waveform(:,i),PPGann,[],[],HRVparams.Fs);
            ppgsqi_numeric = round(mean(ppgsqiMatrix(:,1:3),2)');
            % Write PPG  annotations
            write_ann(strcat(AnnotationFolder, subjectID),HRVparams,'ppg',PPGann);
            write_ann(strcat(AnnotationFolder, subjectID),HRVparams,'sqippg',PPGann(1:length(ppgsqi)),char(ppgsqi),ppgsqi_numeric);
            
            rr = diff(PPGann)./HRVparams.Fs;
            t = PPGann(2:end)./HRVparams.Fs;


        case 'ABP'
            % ABP
            ABPann = run_wabp(Waveform(:,i));
            % ABP SQI
            ABPfeatures =  abpfeature(Waveform(:,i), ABPann, HRVparams.Fs);
            [BeatQ, ~] = jSQI(ABPfeatures, ABPann, Waveform(:,i));
            
            if ~isempty(detectedQRS)
                % Pulse Transit Time
                ptt = pulsetransit(detectedQRS, ABPann);
                % Plot BP vs PTT
                syst = ABPfeatures(:,2);
                if HRVparams.gen_figs
                    figure;
                    plot(syst,ptt(:,3)./HRVparams.Fs,'o');
                    xlabel('BP (mmHg)'); ylabel('PTT (s)');
                    title('Pulse Transit Time - BP vs PTT (ABP - QRS)')
                end
            end
            % Write ABP annotations
            write_ann(strcat(AnnotationFolder, subjectID),HRVparams,'abpm',ABPann);
            write_ann(strcat(AnnotationFolder, subjectID),HRVparams,'sqiabp',BeatQ(:,1));
                      
    end
end
