function [trajectory, distance, path, cost_path] = find_trajectory(C,adj,mid_X,mid_Y,x_st,y_st,x_fin,y_fin,varargin)
%C - cells from decomposition
%adj - adjacency (or costs/weights) matrix
%mid_X,mid_Y - middle points of line segments shared by adjacent cells
%x_st,...,y_fin - coordinates of start/final points
%trajectory - matrix with 2 rows; each column defines a point;
%the trajectory is obtained by linking these successive points (it is an angular trajectory formed by connected line segments)
%distance is the travelled distance (length of trajectory)
%path is the sequence of cells to be followed
%cost_path is the cost of the path in finite-state graph

%%  find start and destination cells
start_cell=0;
destination_cell=0;
for i=1:length(C)   %indices of starting & final cells
    if inpolygon(x_st,y_st,C{i}(1,:),C{i}(2,:))
        start_cell=i;
    end
    if inpolygon(x_fin,y_fin,C{i}(1,:),C{i}(2,:))
        destination_cell=i;
    end
end

if start_cell==0    %start cell not found (either in obstacle, or approximate decomposition like rectangular)
    disp('varargin{1}');
    celldisp(varargin{1});
%     obstacles=varargin{1};  %if this argument was passed
    for i=1:length(obstacles)
        if inpolygon(x_st,y_st,obstacles{i}(1,:),obstacles{i}(2,:))
            fprintf('\nStart position inside obstacle O_%g.\n',i);
            trajectory=[]; distance=inf; path=[]; cost_path=inf;
            return;
        end
    end
    %not in obstacle, choose as start cell having closest centroid
    min_dist=inf;
    for i=1:length(C)   %indices of starting & final cells
        if norm([x_st;y_st]-mean(C{i},2))<min_dist
            min_dist=norm([x_st;y_st]-mean(C{i},2));
            start_cell=i;
        end
    end
    fprintf('\nStart position not inside a cell. Moved to centroid of cell c_%g.\n',i);
end

if destination_cell==0    %start cell not found (either in obstacle, or approximate decomposition like rectangular)
    obstacles=varargin{1};  %if this argument was passed
    for i=1:length(obstacles)
        if inpolygon(x_fin,y_fin,obstacles{i}(1,:),obstacles{i}(2,:))
            fprintf('\nDestination position inside obstacle O_%g.\n',i);
            trajectory=[]; distance=inf; path=[]; cost_path=inf;
            return;
        end
    end
    %not in obstacle, choose as start cell having closest centroid
    min_dist=inf;
    for i=1:length(C)   %indices of starting & final cells
        if norm([x_fin;y_fin]-mean(C{i},2))<min_dist
            min_dist=norm([x_fin;y_fin]-mean(C{i},2));
            destination_cell=i;
        end
    end
    fprintf('\Destination position not inside a cell. Moved to centroid of cell c_%g.\n',i);
end

%% search path
[path, cost_path] = find_path(adj,start_cell,destination_cell);  %sequence of cells to be followed
if isempty(path)
    trajectory=[]; distance=inf; path=[]; cost_path=inf;
    fprintf('\nA path cannot be found.\n');
    return;
end
if length(path)==1  %particular case (start & goal in the same cell)
    trajectory=[[x_st;y_st] , [x_fin;y_fin]];
    distance=norm([x_st;y_st]-[x_fin;y_fin]);
    return
end

%% find points along continuous trajectory (connected line segments)
trajectory=zeros(2,length(path)+1);   %add start point, than middle of line segment shared with next cell, and so on until final cell
distance=0; %for adding travelled distance
trajectory(:,1)=[x_st;y_st];    %starting position
for i=2:length(path)
    trajectory(:,i) = [mid_X(path(i-1),path(i)) ; mid_Y(path(i-1),path(i))];  %middle point of segment shared by two successive states
    distance = distance + norm(trajectory(:,i)-trajectory(:,i-1));
end
trajectory(:,end) = [x_fin;y_fin]; %goal point
distance = distance+norm(trajectory(:,end)-trajectory(:,end-1));

% trajectory=zeros(2,2*length(path)-1);   %add start point, than middle of line segment shared with next cell, than next cell's centroid, than next middle point, and so on
% trajectory(:,1)=[x_st;y_st];    %starting position
% for i=2:(length(path)-1)
%     %for i^th cell, add indices 2*(i-1) and 2*i-1 to trajectory
%     trajectory(:,2*(i-1)) = [mid_X(path(i-1),path(i)) ; mid_Y(path(i-1),path(i))];  %middle point of segment shared by two successive states
%     trajectory(:,2*i-1) = mean(C{path(i)},2);   %centroid of reached cell
% end
% trajectory(:,end-1) = [mid_X(path(end-1),path(end)) ; mid_Y(path(end-1),path(end))];  %middle point of segment leading to final cell
% trajectory(:,end) = [x_fin;y_fin]; %goal point
