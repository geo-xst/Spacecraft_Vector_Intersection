%
% DESCRIPTION
% Script for finding if a vector (with one end to an instrument) intesects
% any part of the spacecraft
%
% INPUT:
%   - model path: a character array with the path of the spacecraft model, 
%        including the extension                                            [.obj or .stl]
%        e.g. 'C:\Users\Darth_Vader\Documents\Cassini_3D_model_example\Cassini_NASA_model.obj'
%   - [x,y,z]: the instrument's location on the model                       [model units / scale]
%   - [vector_matrix]: n x 3 matrix with the vector of interest, e.g.
%       instrument-->Sun                                                    [model units / scale]
%
% OUTPUT:
%   -  index: index of whether the given vector intersects the spacecraft
%       or not; 1 if it does, 0 if it doesn't                               [0 or 1]
%   -  phi: the phi angle of each of the vectors                            [rad] -> [-pi pi]
%   -  theta: the theta angle of each of the vectors                        [rad] -> [-pi/2 pi/2]
%
% ------------------------------------
% NOTES:
% - As it takes quite some time to find the contour for a model it is to
% calculate the contour once and save it. Then every time you want to use
% the contour load the saved one.
% - The units for the instruments x,y,z should be in the same units as the
% model. e.g. if the 1 unit of the model corresponds to 1 metre, the
% instrument's x,y,z "offset" from the s/c origin should also follow this.
% - The units of the vector matrix should follow the units of the model.
%
% ------------------------------------
% Author: George Xystouris (23 March 2023)
% ------------------------------------
% Credits: George Xystouris
%          Oleg Shebanits
%          Chris Arridge
% (this work is submitted for publishing)
% ------------------------------------
% v1

function [index, vec_phi, vec_theta ] = svi_instr_sc_vector_intersection(instr_x, instr_y, instr_z, vector_matrix, model_path)

% Check that file is in a valid file name (.obj or .stl). If it's not, the script stops.
if ~strcmp(model_path(end-3:end),'.obj') && ~strcmp(model_path(end-3:end),'.stl')
    fprintf('Error in opening the model file. Fast checks:\n -File name (the extension .obj or .stl must be part of the file)\n -File location\n');
    return;
end


% CREATE THE MODEL (face, vertices, and normals)
% ----------------------------------
if strcmp(model_path(end-3:end),'.obj');
    [sc_model.v, sc_model.f, ~, ~, sc_model.n,~] = readOBJ(model_path);
else, strcmp(model_path(end-3:end),'.stl');
    [sc_model.f, sc_model.v, sc_model.n]  = stlread(model_path);
end


% CREATE THE INSTRUMENT'S FOV
% ----------------------------------
% Shift the model to have the instrument at the origin (0,0,0)
sc_shifted = sc_model;
sc_shifted.v = [sc_shifted.v(:,1)-instr_x  sc_shifted.v(:,2)-instr_y  sc_shifted.v(:,3)-instr_z];


% Convert from cartesian to spherical coordinates
[Vaz, Vel, Vr] = cart2sph(sc_shifted.v(:,1), sc_shifted.v(:,2), sc_shifted.v(:,3));

% Assign the vertices for each face in the new coordinates
face = [];
for i_face = 1:length(sc_shifted.f)
    face = [face; polyshape( [Vaz(sc_shifted.f(i_face,1)), Vaz(sc_shifted.f(i_face,2)), Vaz(sc_shifted.f(i_face,3))] , ...
        [Vel(sc_shifted.f(i_face,1)), Vel(sc_shifted.f(i_face,2)), Vel(sc_shifted.f(i_face,3))] ) ];
end

% Find the contour of the multiple-polygons plot
sc_contour = union(face);



% CHECK FOR VECTOR INTERSECTIONS
% ----------------------------------
% Create the output variables
index = zeros(size(vector_matrix,1),1);

% Convert the vector from cartesian to spherical
[vec_phi, vec_theta, vec_r] = cart2sph(vector_matrix(:,1),vector_matrix(:,2),vector_matrix(:,3));

% Check whether there is an intersection
wake_ind = isinterior(sc_contour,vec_phi,vec_theta); % this give a logical

% If there an intersection replace the 0 with 1 on the index variable
index(wake_ind) = 1;


end
