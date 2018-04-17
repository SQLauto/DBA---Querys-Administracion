select backup_set_id,bs.media_set_id,convert(varchar(10),database_name) database_name,backup_start_date, bmf.physical_device_name
from backupset bs, backupmediafamily bmf
where bs.media_set_id = bmf.media_set_id
and type = 'D'
and backup_start_date > getdate()-7
order by backup_start_date desc 