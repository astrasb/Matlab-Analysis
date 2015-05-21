function [y, dev] = running_percentile(x, win, p, varargin)
%RUNNING_PERCENTILE Median or percentile over a moving window.
%   Y, DEV = RUNNING_PERCENTILE(X,WIN,P) returns the mean and standard deviation 
%   of the 0-p percentiles of the values in 
%   the vector Y over a moving window of size win, where p and win are
%   scalars. p = 0 gives the rolling minimum, and p = 100 the rolling average of all values.
%
%   running_percentile(X,WIN,P,THRESH) includes a threshold where NaN will be
%   returned in areas where the number of NaN values exceeds THRESH. If no
%   value is specified the default is the window size / 2.
%
%   The definition used is the same as for MATLAB's prctile: if the
%   window is too small for a given percentile, the max or min will be
%   returned. Otherwise linear interpolation is used on the sorted data.
%   Sorting is retained while updating the window, making this faster than
%   repeatedly calling prctile. The edges are handled by duplicating nearby
%   data.
%
%   Examples:
%      y = running_percentile(x,500,10); % 10th percentile of x with
%      a 500 point moving window

%   Author: Levi Golston, 2014

%   Updated: Astra S. Bryant, 2015


% Check inputs
N = length(x);
if win > N || win < 1
    error('window size must be <= size of X and >= 1')
end
if length(win) > 1
    error('win must be a scalar')
end
if p < 0 || p > 100
    error('percentile must be between 0 and 100')
end
if ceil(win) ~= floor(win)
    error('window size must be a whole number')
end
if ~isvector(x)
    error('x must be a vector')
end

if nargin == 4
    NaN_threshold = varargin{1};
else
    NaN_threshold = floor(win/2);
end

% pad edges with data and sort first window
if iscolumn(x)
    x = [x(ceil(win/2)-1 : -1 : 1); x; x(N : -1 : N-floor(win/2)+1); NaN];
else
    x = [x(ceil(win/2)-1 : -1 : 1), x, x(N : -1 : N-floor(win/2)+1), NaN];
end
tmp = sort(x(1:win));
y = NaN(N,1);
dev = NaN(N,1);

offset = length(ceil(win/2)-1 : -1 : 1) + floor(win/2);
numnans = sum(isnan(tmp));

% loop
for i = 1:N
	% Percentile levels given by equation: 100/win*((1:win) - 0.5);
	% solve for desired index
	pt = p*(win-numnans)/100 + 0.5; %this is (or will be with rounding) the index of the sorted x values matched to the requested percentile.
    if numnans > NaN_threshold;   % do nothing
    elseif pt < 1        % not enough points: return min
		y(i) = tmp(1);
	elseif pt > win-numnans     % not enough points (aka asked for max of 100% percentile): return average of all values
		y(i) = mean(tmp(1:(win - numnans)));
        dev(i) = std(tmp(1:(win - numnans)));
	elseif floor(pt) == ceil(pt);  % exact match found
		%y(i) = tmp(pt); %use this to get just that percentile value
        y(i) = mean(tmp(1:pt)); %use this to get the average of the 0-p percentile
        dev(i)= std(tmp(1:pt)); %standard deviation of the 0-p percentile values.
	else             % linear interpolation
		pt = floor(pt);
		x0 = 100*(pt-0.5)/(win - numnans);
		x1 = 100*(pt+0.5)/(win - numnans);
		xfactor = (p - x0)/(x1 - x0);
        temp=tmp(1:pt);
        temp(end)=temp(end)+(tmp(pt+1) - tmp(pt))*xfactor;
		y(i) = mean(temp); %use this to get the average of the 0-p percentile
        dev(i)=std(temp); %standard deviation of the 0-p percentile values.
    end
    
	% find index of oldest value in window
	if isnan(x(i))
		ix = win;  						  % NaN are stored at end of list
		numnans = numnans - 1;
	else
		ix = find(tmp == x(i),1,'first');
	end
	
	% replace with next item in data
	newnum = x(offset + i + 1);
	tmp(ix) = newnum;
	if isnan(newnum)
		numnans = numnans + 1;
	end
	tmp = sort(tmp);

end
