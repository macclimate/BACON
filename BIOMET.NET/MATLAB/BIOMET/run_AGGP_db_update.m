function run_AGGP_db_update(yearIn)

dv=datevec(now);
arg_default('yearIn',dv(1));
sites = {'LGR1'};

db_update_AGGP_sites(yearIn,sites);

exit