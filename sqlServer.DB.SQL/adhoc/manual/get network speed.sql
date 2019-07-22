-- read and write times are factors of network speed between a source and a destination, drive performance, and RAM performance
Select
	session_id,
	protocol_type,
	auth_scheme,
	connect_time,
	num_reads,
	last_read,
	readTime_ms,
	(readTime_ms / 1000) As readTime_s,
	(readTime_ms / (1000 * 60)) As readTime_m,
	(readTime_ms / (1000 * 60 * 60)) As readTime_h,
	num_writes,
	last_write,
	writeTime_ms,
	(writeTime_ms / 1000) As readTime_s,
	(writeTime_ms / (1000 * 60)) As writeTime_m,
	(writeTime_ms / (1000 * 60 * 60)) As writeTime_h,
	net_packet_size
From
	(
		Select
			session_id,
			protocol_type,
			auth_scheme,
			connect_time,
			num_reads,
			last_read,
			DateDiff(ms,connect_time,last_read) As readTime_ms,
			num_writes,
			last_write,
			DateDiff(ms,connect_time,last_write) As writeTime_ms,
			net_packet_size
		From
			sys.dm_exec_connections
	) t

