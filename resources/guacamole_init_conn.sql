-- Add User
-- Generate salt
SET @salt = UNHEX(SHA2(UUID(), 256));

-- Create user and hash password with salt
INSERT INTO guacamole_user (username, password_salt, password_hash)
VALUES ('sdwan-demo', @salt, UNHEX(SHA2(CONCAT('sdwan-demo', HEX(@salt)), 256)));

-- Create connection
INSERT INTO guacamole_connection (connection_name, protocol) VALUES ('Desktop', 'vnc');
SET @id = LAST_INSERT_ID();

-- Add parameters
INSERT INTO guacamole_connection_parameter VALUES (@id, 'hostname', 'desktop');
INSERT INTO guacamole_connection_parameter VALUES (@id, 'port', '5900');


--
INSERT INTO `guacamole_connection` VALUES (1,'desktop',NULL,'vnc',NULL,NULL);
