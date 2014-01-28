-- Copyright [2009-2014] EMBL-European Bioinformatics Institute
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

CREATE TABLE `alignment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `job_id` varchar(48) NOT NULL,
  `source` varchar(16) DEFAULT NULL,
  `species` varchar(48) DEFAULT NULL,
  `qset` varchar(48) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `qstart` bigint(11) DEFAULT NULL,
  `qend` bigint(11) DEFAULT NULL,
  `identity` smallint(6) DEFAULT NULL,
  `evalue` double DEFAULT NULL,
  `result` longtext,
  `region` varchar(32) DEFAULT NULL,
  `tstart` bigint(20) DEFAULT NULL,
  `tend` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `journal` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `create_time` datetime DEFAULT NULL,
  `job_id` varchar(48) NOT NULL DEFAULT '',
  `progress` smallint(6) DEFAULT NULL,
  `status` varchar(16) DEFAULT NULL,
  `counter` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`,`job_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
