%
% This is a generic Biomet function.  Please do not modify.
% (c) Zoran Nesic Feb 9, 2006

if ~isdeployed
    addpath('c:\biomet.net\matlab\biomet');
    addpath('c:\ubc_pc_setup\pc_specific');
    system_dependent('DirChangeHandleWarn', 'Never');
    warning('off','MATLAB:dispatcher:InexactMatch')
    startup_biomet
end
