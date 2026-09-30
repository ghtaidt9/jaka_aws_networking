{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/*-json.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "${log_stream_name}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CWAgent",
    "append_dimensions": {
      "InstanceId": "$${aws:InstanceId}",
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
    },
    "aggregation_dimensions": [["AutoScalingGroupName"], ["InstanceId"]],
    "metrics_collected": {
      "mem"   :{"measurement": ["mem_used_percent"], "metrics_collection_interval": 60},
      "diskio":{"measurement": ["reads", "writes", "read_bytes", "write_bytes"], "resources": ["*"], "metrics_collection_interval": 60},
      "disk"  :{"measurement": ["disk_used_percent"], "resources": ["/"], "metrics_collection_interval": 60},
      "cpu"   :{"measurement": ["cpu_usage_idle", "cpu_usage_iowait"], "totalcpu": true, "metrics_collection_interval": 60},
      "net"   :{"measurement": ["bytes_sent", "bytes_recv"], "metrics_collection_interval": 60}
    }
  }
}
