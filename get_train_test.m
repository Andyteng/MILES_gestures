function[x,z,y_est_train_accel,y_est_test_accel] = get_train_test(input_dir,subjects_train,subjects_test,accel_prob,used_ones_accel,times)

    disp(['Getting train/test for ' num2str(length(subjects)) ' subjects, leaving out subject ' num2str(subject_out)])

	disp(['Accessing ' input_dir])

	x=[];
    %y_est_train_accel={};
    %y_est_test_accel={};
    %y_true_train={};
    %y_true_test={};
    
    y_est_train_accel=[];
    y_est_test_accel=[];
    y_true_train=[];
    y_true_test=[];


	for e=1:length(subjects_train)
        
		filename=[input_dir 'bag_GlobId' num2str(subjects(e)) '.mat'];
		disp(['Loading ' filename])
		try		
			load(filename);
            T=csvread([input_dir 'T_GlobId' num2str(subjects(e)) '.csv']);
            T_=unique(T);
            t_max=max(unique(T));
			a = a*scalem(a,'variance'); %scale features for fair comparison
            [bags,~] = getbags(a);
            nrbags=length(bags);
            bag_lab=round(ispositive(getbaglabs(a)));
    
            %load also predictions from accel
            id=find(used_ones_accel==subjects(e));
            y_accel=ones(1,nrbags)*0.5; %give random prob 
            
            if ~isempty(id)
                
				t_=times{1,id};
				ids_=find(ismember(T_,t_));
				ids2_=find(ismember(t_,T_));
				y_accel(ids_)=AllProbs{1,id}(ids2_);                

                
            end
            disp(['NumBags: ' num2str(nrbags)]);
			disp(['Num Yaccel est: ' num2str(length(y_accel))]);
			
			if ~isequal(subjects(e),subject_out)				
				if isempty(x)
					x=a;                   
				else
					x=milmerge(x,a); %training set, complete                  
				end
				y_est_train_accel=[y_est_train_accel y_accel];
				y_true_train=[y_true_train bag_lab'];
			else
				z=a; %test set
				y_true_test=[y_true_test bag_lab'];
				y_est_test_accel=[y_est_test_accel y_accel];
			end
			
        catch ch
            disp('Problems!')
		end
	end		
	disp('Original set of bags for training: ');
	mildisp(x)
	

end
