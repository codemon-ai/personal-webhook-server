module.exports = {
  apps: [
    {
      name: 'cc-webhook',
      script: 'dist/server.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '200M',
      env: {
        NODE_ENV: 'production',
      },
      error_file: 'logs/error.log',
      out_file: 'logs/output.log',
      log_file: 'logs/combined.log',
      time: true,
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    },
    {
      name: 'cc-webhook-ngrok',
      script: 'scripts/ngrok-tunnel.sh',
      instances: 1,
      autorestart: true,
      watch: false,
      error_file: 'logs/ngrok-error.log',
      out_file: 'logs/ngrok-output.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    },
  ],
};
