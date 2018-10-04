function[x,z] = get_train_test_noaccel(input_dir,subjects_train,subjects_test)
   
	disp(['Accessing ' input_dir])

	x=[];
	z=[];
    %y_est_train_accel={};
    %y_est_test_accel={};
    %y_true_train={};
    %y_true_test={};
    
    y_est_train_accel=[];
    y_est_test_accel=[];
    y_true_train=[];
    y_true_test=[];


	disp('Getting train subjects')
	subjects=subjects_train;
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
            
            disp(['NumBags: ' num2str(nrbags)]);
			
			if isempty(x)
				x=a;                   
			else
				x=milmerge(x,a); %training set, complete                  
			end					
			
        catch ch
            disp('Problems!')
		end
	end		
	disp('Original set of bags for training: ');
	mildisp(x)
	
	disp('Getting train subjects')
	subjects=subjects_test;
	for e=1:length(subjects_test)
        
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
            
            disp(['NumBags: ' num2str(nrbags)]);
			
			
			if isempty(z)
				z=a;                   
			else
				z=milmerge(z,a); %training set, complete                  
			end					
			
        catch ch
            disp('Problems!')
		end
	end		
	disp('Original set of bags for testing: ');
	mildisp(z)
	
	
	
end
