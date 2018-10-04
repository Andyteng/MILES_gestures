function[] = run_baseline_video(subject_out,stratified,NumBags,subjects_train,subjects_test)

	path(pathdef);
	addpath(genpath('/Users/Andyteng/Dropbox/prtools'));
	addpath(genpath('/Users/Andyteng/Dropbox/Graduation_Project/Code/MILES_gestures/dd_tools'));
	addpath(genpath('/Users/Andyteng/Dropbox/Graduation_Project/Code/MILES_gestures/mil'));
	addpath(genpath('/Users/Andyteng/Dropbox/Graduation_Project/Code/MILES_gestures/SLEP_package_4.1'));

	input_dir='/Users/Andyteng/Dropbox/Graduation_Project/Code/MILES_gestures/bags/';
	output_dir='/Users/Andyteng/Dropbox/Graduation_Project/Code/MILES_gestures/results/decision_fusion/';
	mkdir(output_dir);

	%subjects_train=[5,6,8,9,10,12,13,14,16,20,21,22,23,24,25,27,28,29,30,31,32,34,35,36,38,42,44,45,46,47,49,50,52,53,56,57,60,66,69,70,71,72,73,74,75,76,77,78,81,82,87,88,89,92];
	%subjects_test=[2,3,15,17,26,39,40,43,51,54,59,65,67,80,83,85];
	
    subjects_train = [9,12,13,24,];
    subjects_test = [2,5];
    
	l=0.007;
	KPAR=20;
	
	with_accel=0;
	
	
	if with_accel==1
		load('all_Probs_accel.mat'); %files that Ekin gave me
		used_ones_accel=csvread('used_ones.csv');
		accel_times=load('times.mat');
		[x,z,y_est_train_accel,y_est_test_accel]= get_train_test(input_dir, subjects_train, subjects_test, AllProbs, used_ones_accel, accel_times.times);
	else
		[x,z] = get_train_test_noaccel(input_dir,subjects_train,subjects_test)
	end
	
	[bags,lab] = getbags(z);
	[Ip_test,In_test] = find_positive(lab);
	
	if ~isempty(Ip_test)	
		
		disp('Performing training using different random sampligs in a stratified manner...');
		%now, from training data randomly select only k bags							
		
		[x_]=do_bags_sampling_noaccel(x,stratified,NumBags);
		
		disp('Classifying...')
		w_miles=miles_SLEP(x_,l,'r',KPAR);
		disp('Done!');
		
		disp('Getting miles predictions on train set...')
		out_miles_train=x_*w_miles;
		p_miles_train=out_miles_train*classc;		
		p_miles_train=+p_miles_train(:,2);
		est_lab_miles_train =out_miles_train*labeld;
		disp('Done!')
		
		disp('Obtaining test results from miles')
		out_miles_test=z*w_miles;
		p_miles_test=out_miles_test*classc;
		p_miles_test=+p_miles_test(:,2); %probability of class positive
		auc_miles=dd_auc(out_miles_test*milroc)
		y_est_miles_test=out_miles_test*labeld;		
		disp('Done!')
		
	end

end
