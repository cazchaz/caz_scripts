SELECT s1.username || ' @ ' || s1.machine || ' ''SID,SERIAL#'' = ''' || s1.sid || ',' || s1.serial# || ''' has been blocking ' || s2.username || ' @ ' || s2.machine || ' ''SID,SERIAL#'' = ''' || s2.sid || ',' || s2.serial# || ''' for ' || l1.ctime || ' seconds.' AS blocking_status 

FROM v$lock l1, v$session s1, v$lock l2, v$session s2 

WHERE s1.sid=l1.sid AND s2.sid=l2.sid 

AND l1.BLOCK=1 AND l2.request > 0 

AND l1.id1 = l2.id1 

AND l1.id2 = l2.id2;  

--select SID, SERIAL#, USERNAME, LOCKWAIT, STATUS, OSUSER, PROCESS, PROGRAM, TERMINAL from v$session; 