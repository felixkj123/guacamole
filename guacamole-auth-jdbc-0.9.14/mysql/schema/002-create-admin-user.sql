--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--

-- Create default user "guacadmin" with password "guacadmin"
INSERT INTO guacamole_user (username, password_hash, password_salt, password_date)
VALUES ('accl',
    x'CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960',  -- 'guacadmin'
    x'FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264',
    NOW());

-- Grant this user all system permissions
INSERT INTO guacamole_system_permission
SELECT user_id, permission
FROM (
          SELECT 'accl'  AS username, 'CREATE_CONNECTION'       AS permission
    UNION SELECT 'accl'  AS username, 'CREATE_CONNECTION_GROUP' AS permission
    UNION SELECT 'accl'  AS username, 'CREATE_SHARING_PROFILE'  AS permission
    UNION SELECT 'accl'  AS username, 'CREATE_USER'             AS permission
    UNION SELECT 'accl'  AS username, 'ADMINISTER'              AS permission
) permissions
JOIN guacamole_user ON permissions.username = guacamole_user.username;

-- Grant admin permission to read/update/administer self
INSERT INTO guacamole_user_permission
SELECT guacamole_user.user_id, affected.user_id, permission
FROM (
          SELECT 'accl' AS username, 'accl' AS affected_username, 'READ'       AS permission
    UNION SELECT 'accl' AS username, 'accl' AS affected_username, 'UPDATE'     AS permission
    UNION SELECT 'accl' AS username, 'accl' AS affected_username, 'ADMINISTER' AS permission
) permissions
JOIN guacamole_user          ON permissions.username = guacamole_user.username
JOIN guacamole_user affected ON permissions.affected_username = affected.username;

