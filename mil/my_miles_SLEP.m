%MILES MultiInstance Learning in Embedded Subspaces
%
%    W = MILES(A,LAMBDA,KTYPE,KPAR)
%
% INPUT
%   A       MIL dataset
%   LAMBDA  Tradeoff parameter (default = 0.1)
%   KTYPE   Kernel type (default = 'r')
%   KPAR    Kernel parameter (default = 5)
%
% OUTPUT
%   W       MILES classifier
%
% DESCRIPTION
% Train the MILES learner on dataset A, where bags of A a represented by
% the MAXIMUM similarity to all other instances. The similarity is
% measured by the kernel KTYPE using dd_proxm, with parameter(s) KPAR.
% On this dissimilarity represention a sparse linear classifier is
% trained. For more information, please read the paper.
% 
% The kernel KTYPE is per default 'r' (radial basis function)
% When KPAR = NaN, the parameter will be optimized on the training
% set using NNDIST(A,1)
% 
% REFERENCE
%@article{CheBiWan2007,
%	author = {Chen, Y. and Bi, J. and Wang, J.Z.},
%	title = {{MILES}: Multiple-Instance learning via embedded instance
%		selection},
%	journal = {IEEE Transactions on Pattern Analysis and Machine
%		Intelligence},
%	volume = {28},
%	number = {12},
%	pages = {1931-1947},
%	year = {2006}}
%
% SEE ALSO
%   dd_proxm, nndist

% Copyright: D.M.J. Tax, D.M.J.Tax@prtools.org
% Faculty EWI, Delft University of Technology
% P.O. Box 5031, 2600 GA Delft, The Netherlands
  
%function [w,u] = miles(a,C,ktype,kpar,chooseglpk)
function [w,u] = miles(varargin)

argin= shiftargin(varargin,'scalar');
argin = setdefaults(argin,[],0.1,'r',5,1);

if mapping_task(argin,'definition')
   [a,C,ktype,kpar,chooseglpk] = deal(argin{:});
   W = define_mapping(argin,'untrained','MILES %s=%f',ktype,kpar(1));
	w = setbatch(W,0);  %NEVER use batches!!
   
elseif mapping_task(argin,'training')
   [a,lambda,ktype,kpar,chooseglpk] = deal(argin{:});
   C=lambda;
	% some checking:
	if ~ismilset(a)
		error('I need a MIL dataset.');
	end
	% compute bag similarity to objects:
	[n,dim] = size(a);
	[bag,baglab] = getbags(a);
    y = 2*ispositive(baglab)-1;   
	nrbags = length(bag);
	% define the kernel
   if strcmp(ktype,'r') && isnan(kpar(1))
      kpar(1) = nndist(a,1);
   end
   
   % first we need the instance-instance similarities
    disp('Creating instance-instance similarities...')
	kernelmap = dd_proxm(a,ktype,kpar(1));
    disp(['Size of kernelmap: ' num2str(size(kernelmap,1)) 'x' num2str(size(kernelmap,2))])
	m = zeros(nrbags,size(kernelmap,2));
    disp(['Size of m: ' num2str(size(m,1)) 'x' num2str(size(m,2))])
    disp('Calculating distances...')
    tstart = tic;
	for i=1:nrbags
		% select the most similar one:
		d = bag{i}*kernelmap;
		m(i,:) = max(+d,[],1);  % do we need frac here?
    end
    telapsed = toc(tstart);
    disp(['Done! Time spend: ' num2str(telapsed) ' seconds.']);
    %%added by L.Cabrera, supported in original miles.m
    Cweights = repmat(C,nrbags,1);
    nrcon = size(m,2); % number of potential concepts
    %reweigh to cope with class imbalance:
    Ipos = (y==+1);
    Ineg = (y==-1);
    Cweights(Ipos)=Cweights(Ipos)/sum(Ipos);
    Cweights(Ineg)=Cweights(Ineg)/sum(Ineg);
	f = [ones(2*nrcon,1)/(2*nrcon);		  Cweights;		  0];
    A = -[repmat(y,1,nrcon).*m, -repmat(y,1,nrcon).*m, speye(nrbags), y];
    %%%
	% setup the optimisation:
   if ~exist('LogisticR')
      error('The SLEP package is not in your path!');
   end
   disp('Setting up optimization...')
   opts = [];
   opts.init = 2; % starting from a zero point
   opts.tFlag = 5; %run .maxIter iterations
   opts.maxIter = 100;

   opts.rsL2 = 0;  % no rho.
   opts.nFlag = 0; % no normalization of data
   opts.rFlag = 0; % use the given lambda
   % weight for positive and negative examples
   sz = classsizes(a);
   opts.Weight = [1/sz(1) 1/sz(2)];

   opts.mFlag = 0; % treating it as a compositive function (DXD???)
   opts.lFlag = 0; % Nemirovski's line search

   disp('Solving...')
   disp('Start timer')
   tstart = tic;
   %[w1,w0,funVal1,ValueL1] = LogisticR(m,y,lambda,opts);
   [w1,w0,funVal1,ValueL1] = LogisticR(A',f,lambda,opts);
   telapsed = toc(tstart);
   disp(['Done! Time spend: ' num2str(telapsed) ' seconds.']);


	% what classifier do we have now...
	I = find(abs(w1)>1e-9);
	if isempty(I)
		warning('All weights are zero.');
		I = 1; 
	end
	W.w = w1(I);
	W.w0 = w0;
	W.sva = +a(I,:);
	W.ktype = ktype;
	W.kpar = kpar;
	W.kernelmap = kernelmap;
	W.I = I;
id = getident(a);
W.id = id(I);
	w = prmapping(mfilename,'trained',W,getlablist(a),dim,2);
	w = setname(w,'MILES %s=%f',ktype,kpar(1));
	w = setbatch(w,0);  %NEVER use batches!!

elseif mapping_task(argin,'trained execution')  %testing
   [a,C] = deal(argin{1:2});
	% evaluation
	a = genmil(a);
	W = getdata(C);
	[bag,baglab,bagid] = getbags(a);
	n = size(bag,1);
	out = zeros(n,1);
   instout = [];
	for i=1:n
		d = bag{i}*W.kernelmap;
      instout = [instout; +d(:,W.I)*W.w + W.w0];
		out(i,1) = max(+d(:,W.I),[],1)*W.w + W.w0;
	end

	%w = dataset([-out out],baglab,'featlab',getlabels(frac));
	s_out = sigm(out);
	w = prdataset([1-s_out s_out],baglab,'featlab',getlabels(C));
	w = setprior(w,getprior(a,0));
	w = setident(w,bagid,'milbag');
   % for the instance labels
   u = prdataset([1-instout instout],getlab(a));
else
   error('Illegal call to MILES.');
end

