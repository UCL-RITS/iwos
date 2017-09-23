directTrimThis{
    foreach ( *CacheFile in SELECT DATA_ID, DATA_REPL_NUM, DATA_PATH, DATA_CHECKSUM, COLL_NAME, DATA_NAME where DATA_RESC_HIER = 'wos;wosCache' and DATA_ID = '*DATA_ID' ){
        *File.DATA_ID = *CacheFile.DATA_ID;
        *File.CACHE_REPL = *CacheFile.DATA_REPL_NUM;
        *File.CACHE_PATH = *CacheFile.DATA_PATH;
        *File.CACHE_CHECKSUM = *CacheFile.DATA_CHECKSUM;
        *File.IRODS_PATH = (*CacheFile.COLL_NAME)++"/"++(*CacheFile.DATA_NAME);

        *File.ARCHIVE_REPL='';
        *File.ARCHIVE_CHECKSUM='';
        #There could be more than one archive replica...
        foreach ( *ArchiveFile in SELECT DATA_REPL_NUM, DATA_CHECKSUM where DATA_ID = (*CacheFile.DATA_ID) and DATA_RESC_HIER = 'wos;wosArchive' ){
            *File.ARCHIVE_REPL = *ArchiveFile.DATA_REPL_NUM;
            *File.ARCHIVE_CHECKSUM = *ArchiveFile.DATA_CHECKSUM;
        }

        #Variables initialisation complete.....
        writeLine('serverLog', 'ASYNC --------------------------------------------------------------------------');

        #If there is a cache checksum and it is the same as the archive checksum...
        if ( (*File.CACHE_CHECKSUM) != '' && ( (*File.CACHE_CHECKSUM) == (*File.ARCHIVE_CHECKSUM) ) ){
            writeLine('serverLog', 'ASYNC Checksums match - '++(*File.DATA_ID));
            #If there is no archive replica
            if ( (*File.ARCHIVE_REPL) == '' ){
                writeLine('serverLog', 'ASYNC ******ERROR****** Checksums match but no archive copy... SOMETHING HAS GONE WRONG - '++(*File.DATA_ID));
            } else {
            # There IS an archive replica - so ready to trim the cache copy
                writeLine("serverLog", "ASYNC Checksums match and copy exists in archive so trim cache replica "++(*File.CACHE_REPL)++" - "++(*File.DATA_ID));
                *Status=0
                msiDataObjTrim((*File.IRODS_PATH),"null",(*File.CACHE_REPL),"1","IRODS_ADMIN_KW",*Status);
                if ( *Status == 0 ){
                    writeLine('stdout', 'Failed trim ERR1 OID = '++(*File.IRODS_PATH));
                }
            }
        } else {
        #No checksum or checksums do not match
            #writeLine('serverLog', 'No checksums or checksums DO NOT match - '++(*File.DATA_ID));
            #If there is no archive replica
            if ( (*File.ARCHIVE_REPL) == '' ){
                writeLine( "serverLog", "ASYNC "++(*File.DATA_ID)++" in cache, not in archive" );
                #If no cache checksum -> msiDataObjChksum
                if ( (*File.CACHE_CHECKSUM) == '' ){
                    writeLine( "serverLog", "ASYNC " ++(*File.DATA_ID)++" no checksum - running msiDataObjChksum" );
                    msiDataObjChksum( (*File.IRODS_PATH), 'ChksumAll=++++forceChksum=', *checksum );
                    writeLine('serverLog', 'ASYNC Checksum generated - *checksum for '++(*File.DATA_ID));
                }
                #We now MUST have a cache checksum -> sync to archive
                *sync_err = msisync_to_archive('wos;wosCache', (*File.CACHE_PATH), (*File.IRODS_PATH));
                if ( 0 != *sync_err ) {
                    writeLine( "serverLog", "ASYNC Sync_to_archive first error, *sync_err - "++(*File.DATA_ID)++" .......retrying" );
                    *sync_err = msisync_to_archive('wos;wosCache', (*File.CACHE_PATH), (*File.IRODS_PATH));
                    if ( 0 != *sync_err ) {
                        writeLine( "serverLog", "ASYNC Sync_to_archive second error, *sync_err - "++(*File.DATA_ID)++" .......retrying" );
                        *sync_err = msisync_to_archive('wos;wosCache', (*File.CACHE_PATH), (*File.IRODS_PATH));
                        if ( 0 != *sync_err ) {
                            writeLine( "serverLog", "ASYNC Sync to archive failed after three attempts.... *sync_err - "++(*File.DATA_ID));
                            fail;
                        }
                    }
                } else {
                    writeLine( "serverLog", "ASYNC "++(*File.DATA_ID)++" sync'd to archive" );
                    #Can now trim the cache copy
                    msiDataObjTrim((*File.IRODS_PATH),"null",(*File.CACHE_REPL),"1","IRODS_ADMIN_KW",*Status);
                    if ( *Status == 0 ){
                        writeLine('stdout', 'Failed trim ERR2 OID = '++(*File.IRODS_PATH));
                    } else {
                        writeLine( "serverLog", "ASYNC "++(*File.DATA_ID)++" cache copy trimmed" );
                    }
                }
            } else {
            # There is an archive replica, but either no checksum or a checksum mismatch
                writeLine( 'serverLog', 'ASYNC Archive replica='++(*File.ARCHIVE_REPL)++' - '++(*File.DATA_ID));
                writeLine( 'serverLog', 'ASYNC Cache replica='++(*File.CACHE_REPL)++' - '++(*File.DATA_ID));
                # If no cache replica -> pull to cache with msiDataObjChksum
                if ( (*File.CACHE_REPL) == '' ){
                    writeLine('serverLog',"ASYNC Archive checksum = "++(*File.ARCHIVE_CHECKSUM)++" - need to pull to cache and checksum");
                    msiDataObjChksum( (*File.IRODS_PATH), 'replNum='++(*File.CACHE_REPL), *checksum );
                    writeLine('serverLog', 'ASYNC Checksum generated - *checksum for '++(*File.DATA_ID));
                } else {
                #Archive must be old so trim it...
                    writeLine('serverLog', 'ASYNC Cache replica='++(*File.CACHE_REPL)++' - '++(*File.DATA_ID));
                    #writeLine('serverLog', "ASYNC Deleting the archive copy as there is a checksum error and there is a copy in cache - "++(*File.DATA_ID));
                    writeLine('serverLog', "ASYNC Re-sync over the archive copy as it is old - "++(*File.DATA_ID));
                    #*Status=0
                    #msiDataObjTrim((*File.IRODS_PATH),"null",(*File.ARCHIVE_REPL),"1","IRODS_ADMIN_KW",*Status);
                    #if ( *Status == 0 ){
                    #    writeLine('stdout', 'Failed trim ERR3 OID = '++(*File.IRODS_PATH));
                    #} else {
                    #    writeLine( "serverLog", "ASYNC "++(*File.DATA_ID)++" replica "++(*File.ARCHIVE_REPL)++" trimmed." );
                    #}
                    if ( (*File.CACHE_CHECKSUM) == '' ) {
                        msiDataObjChksum( (*File.IRODS_PATH), 'replNum='++(*File.CACHE_REPL), *checksum );
                        writeLine('serverLog', "ASYNC "++'Checksum generated - *checksum for '++(*File.DATA_ID));
                    }
                    #We now MUST have a cache checksum -> sync to archive
                    *sync_err = msisync_to_archive('wos;wosCache', (*File.CACHE_PATH), (*File.IRODS_PATH));
                    if ( 0 != *sync_err ) {
                        writeLine( "serverLog", "ASYNC Sync_to_archive first error, *sync_err - "++(*File.DATA_ID)++" .......retrying" );
                        *sync_err = msisync_to_archive('wos;wosCache', (*File.CACHE_PATH), (*File.IRODS_PATH));
                        if ( 0 != *sync_err ) {
                            writeLine( "serverLog", "ASYNC Sync_to_archive second error, *sync_err - "++(*File.DATA_ID)++" .......retrying" );
                            *sync_err = msisync_to_archive('wos;wosCache', (*File.CACHE_PATH), (*File.IRODS_PATH));
                            if ( 0 != *sync_err ) {
                                writeLine( "serverLog", "ASYNC Sync to archive failed after three attempts.... *sync_err - "++(*File.DATA_ID));
                                fail;
                            }
                        }
                    } else {
                        writeLine( "serverLog", "ASYNC "++(*File.DATA_ID)++" sync'd to archive" );
                        #Can now trim the cache copy
                        msiDataObjTrim((*File.IRODS_PATH),"null",(*File.CACHE_REPL),"1","IRODS_ADMIN_KW",*Status);
                        if ( *Status == 0 ){
                            writeLine('stdout', 'Failed trim ERR4 OID = '++(*File.IRODS_PATH));
                        } else {
                            writeLine( "serverLog", "ASYNC "++(*File.DATA_ID)++" cache copy trimmed" );
                        }
                    }
                } #End of "Archive must be old, so trim it"
            } #End of ArchiveRepl != ""
        } #End of (CacheChecksum == "" | CacheChecksum != ArchiveChecksum)
    } #End of foreach in Cache
} #End of newTrim
INPUT *DATA_ID=$
OUTPUT ruleExecOut
