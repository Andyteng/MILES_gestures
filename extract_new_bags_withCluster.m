
function extract_new_bags_withCluster(subject_id,init_frame,end_frame)

	
	path(pathdef);

	%change *MYDIR* for proper firectories
	addpath(genpath('/*MYDIR*/MATLAB/code/prtools'));
	addpath(genpath('/*MYDIR*/MATLAB/code/mil'));
	addpath(genpath('/*MYDIR*/MATLAB/code/dd_tools'));


	w_size=60;
	k=20;
	
	disp(['Extracting bags for a window size of ' num2str(w_size) ' and a k of ' num2str(k)])
	
	L=15; %fixed for the DT extraction, if change there must be change here
	%interv_len=end_frame-init_frame;

	%overlap=round(w_size/2); 
	overlap=0; % tests with no overlap

	input_dir=['/*MYDIR*/DT/']; %change to dir where DT csv files are

	%% Load Data

	%load annotations
	annotations_dir='/*MYDIR*/data/annotations/';
	load([annotations_dir 'Annotations_MatchNMingle_version2_FIXED.mat']);

	% CHANGES depeding the action 
	%gestures=new_LABELS_fixed(init_frame:end_frame,(subject_id-1)*9+5);
	speak=new_LABELS_fixed(init_frame:end_frame,(subject_id-1)*9+4);

	%load DT
	DT_dir=[input_dir 'subject' num2str(subject_id) '/'];
	DT_over=(L-(L*85/100));
	pt=1;

	%% extract entire data for bags
	X=[];
	Y=[];
	T=[];
	B_ID=[];

	count=1;

	while(pt+w_size-1<interv_len)

		disp(['Window from ' num2str(pt) ' to ' num2str(pt+w_size-1)])

		%select interval of DTs
		ids=pt-DT_over:pt+w_size+DT_over-1;
		ids(ids<=0)=[];
		ids(ids>=end_frame)=[];

		x_=[];
		y_=[];
		t_=[];
		bagid_=[];
		
		for d=1:length(ids)
			try
				file_name=[DT_dir num2str(ids(d)) '.csv'];
				f=dlmread(file_name,'\t');
				x_=[x_; f];
				
				
			catch 
				%warning(['No trajectories for ' num2str(ids(d))]);
			end
		end
		if k<size(x_,1)
        	[~,C,~,~]=kmeans(x_,k);
		else
			C=x_;
		end
		%this_gest=gestures(pt:pt+w_size-1);		
		this_gest=speak(pt:pt+w_size-1);
        
        maj_vote=round(sum(this_gest)/w_size);
        y_=[y_,maj_vote*ones(1,size(C,1))];
        t_=[t_,pt*ones(1,size(C,1))];
        bagid_=[bagid_,count*ones(1,size(C,1))];
		
		X=[X; C];
		Y=[Y, y_];
		T=[T, t_];
		B_ID=[B_ID, bagid_];
		pt=pt+w_size-overlap-1;
		count=count+1;
	end

	%% put it in prtool format
	Y_ = genmillabels(Y',1);
	a = genmil(X, Y_, B_ID'); % create dataset using prtools format
	mildisp(a)

output_dir='/*MYDIR*/bags/';

disp(['Saving bag struct at ' output_dir 'bag_GlobId' num2str(subject_id) '.mat']);
save([output_dir 'bag_GlobId' num2str(subject_id) '.mat'],'a','-v7.3');
csvwrite([output_dir 'T_GlobId' num2str(subject_id) '.csv'],T);
csvwrite([output_dir 'Y_GlobId' num2str(subject_id) '.csv'],Y);
disp('Done!');

	
end




