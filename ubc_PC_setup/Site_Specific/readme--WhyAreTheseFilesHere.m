23-Feb-2012, JJB

The licor.m file originally was located in the /biomet.net/Matlab/BOREAS/ directory.

However, this file is modified based on what IRGAs the research group is using, and our version will ultimately look different than what UBC will generate.  Therefore, when they send us an updated version of biomet.net and ask us to simply replace the existing, we would end up copying over the licor.m file that was modified for our own needs, and we'd start getting errors.

To fix this, we've now put the licor.m file in this folder, and made links to this file (named exactly the same) in the folders for each site.  Since these folders are higher on the path than the biomet.net folder during flux calculations, the contents of this licor.m file will always be the one that's used for our calculations.

23-March-2018, JJB
- The same now goes for fr_read_TurkeyPointClim.m 

