function isis = isi(data)
% Function to calculate inter-spike intervals

isis=diff(data.tSpikes);
%data.isis=data.isis(data.isis>0); % to remove negative values
%due to spike train change, but this is actually helpful to have to
%separate isis later on