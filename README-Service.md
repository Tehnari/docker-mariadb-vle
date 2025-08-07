# How to make another service depend on the `docker-mariadb-vle.service`

> **Copyright (c) 2025 Constantin Sclifos** - [sclifcon@gmail.com](mailto:sclifcon@gmail.com)  
> Licensed under MIT License - see [LICENSE](LICENSE) for details

To make another service depend on the `docker-mariadb-vle.service`, you need to add the appropriate dependencies in the systemd service file. Here are the different ways to do this:

## 1. **Basic Dependency (Requires)**
If your service absolutely needs MariaDB to be running:

```ini
[Unit]
Description=Your Service
Requires=docker-mariadb-vle.service
After=docker-mariadb-vle.service
# ... other unit settings

[Service]
# ... your service configuration

[Install]
WantedBy=multi-user.target
```

## 2. **Soft Dependency (Wants)**
If your service can start without MariaDB but prefers it to be running:

```ini
[Unit]
Description=Your Service
Wants=docker-mariadb-vle.service
After=docker-mariadb-vle.service
# ... other unit settings

[Service]
# ... your service configuration

[Install]
WantedBy=multi-user.target
```

## 3. **Complete Example**
Here's a complete example for a service that depends on MariaDB:

```ini
[Unit]
Description=Your Application Service
Requires=docker-mariadb-vle.service
After=docker-mariadb-vle.service docker.service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/your/app
ExecStart=/path/to/your/app/start.sh
ExecStop=/path/to/your/app/stop.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## 4. **Dependency Types Explained:**

- **`Requires=`** - Hard dependency. If MariaDB fails, your service will also stop
- **`Wants=`** - Soft dependency. Your service will start even if MariaDB fails
- **`After=`** - Ordering dependency. Your service starts after MariaDB
- **`Before=`** - Reverse ordering. MariaDB starts before your service

## 5. **For Docker Compose Services**
If you're creating another Docker Compose service that depends on MariaDB:

```ini
[Unit]
Description=Your Docker Compose Service
Requires=docker-mariadb-vle.service docker.service
After=docker-mariadb-vle.service docker.service
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/your/docker-compose
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
ExecReload=/usr/bin/docker compose restart
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

## 6. **Check Dependencies**
To see what services depend on MariaDB:

```bash
systemctl list-dependencies docker-mariadb-vle.service
```

## 7. **Reload Systemd**
After creating your service file:

```bash
sudo systemctl daemon-reload
sudo systemctl enable your-service.service
sudo systemctl start your-service.service
```

The key is using `Requires=docker-mariadb-vle.service` for hard dependencies or `Wants=docker-mariadb-vle.service` for soft dependencies, along with `After=docker-mariadb-vle.service` to ensure proper startup order.