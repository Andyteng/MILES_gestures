function[x_]=do_bags_sampling_noaccel(x,stratified,NumBags)

    %train MILES
    disp('Performing random sampling of bags...')
    [bags,bagslab] = getbags(x);
    nrbags=length(bags);
    [Ip_train,In_train] = find_positive(bagslab);
	
    
    if stratified==1
		disp('Using stratified option')
        y_pos=randsample(Ip_train,round(NumBags/2),'false');
        y_neg=randsample(In_train,round(NumBags/2),'false');
        y=[y_pos; y_neg];			
    elseif stratified==0
		disp('Using normal random sampling')
        y = randsample(nrbags,NumBags,'false'); %no replacement				        
    end

    select_bags=bags(y);
    select_bagslab=bagslab(y,:);

    x_ = genmil(select_bags, select_bagslab); %subset for training
    disp('Training data for this fold:');
    mildisp(x_)
    
end
