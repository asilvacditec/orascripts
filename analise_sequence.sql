select a.id_mon, a.dt_monitor, a.nm_instancia, a.sequence_owner, a.sequence_name, a.cache_size, a.order_flag,
       round(((a.last_number) / ((a.nr_tempo_delta) / 60) / a.cache_size), 2) avg_req_time_per_min
from dqarep.t_dqa_seqstat a
inner join dqarep.t_dqa_log_item b
on a.id_mon = b.id_mon
where nm_instancia = 'DENISE'
and sequence_owner = 'ADMINPROV2_10'
and sequence_name = 'TEM_TRANS_ID_NR_SEQ'
and a.nr_tempo_delta > 0
and b.is_sucess = 'S'
and a.cache_size > 0
