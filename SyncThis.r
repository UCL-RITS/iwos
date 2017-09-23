syncThisDataID{
    foreach (*File in SELECT DATA_PATH, DATA_NAME, COLL_NAME WHERE DATA_ID = '*DATA_ID'){
        *sync_err = msisync_to_archive('wos;wosCache', (*File.DATA_PATH), (*File.COLL_NAME)++'/'++(*File.DATA_NAME));
        if ( 0 != *sync_err ) {
            writeLine( "stdout", "Sync_to_archive error, *sync_err - "++*U );
        }
    }
}
INPUT *DATA_ID=$
OUTPUT ruleExecOut
