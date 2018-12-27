# TurboBee
 
OpenResty caching layer

Install turbobee and its dependencies into `/usr/local/openresty/luajit/lib/luarocks/rocks/`:

```
luarocks make
```

turbobee 0.1-1 is now installed in /usr/local/openresty/luajit (license: GNU Affero General Public License v3.0)

## Create database

```
create database turbobee;
create user turbobee with encrypted password 'secret';
grant all privileges on database turbobee to turbobee;
```

Connect with the user and create table and a test row:

```
CREATE TABLE pages
(
id BIGSERIAL,
qid varchar(32),
target varchar(75),
content_type varchar(10),
content TEXT,
created timestamp without time zone,
updated timestamp without time zone,
expires timestamp without time zone,
eol timestamp without time zone,
owner integer
);

INSERT INTO pages (qid, target, content_type, content, created, updated, expires, eol, owner)
VALUES (
'2018EPJWC.18608001A',
'html',
'ui.adsabs.harvard.edu/#abs/2018EPJWC.18608001A/abstract',
'<p>From db</p>',
TIMESTAMP '2018-12-10 12:00:00',
TIMESTAMP '2018-12-10 12:00:00',
TIMESTAMP '2019-01-10 12:00:00',
TIMESTAMP '2020-01-10 12:00:00',
0
);

```

If it was installed in `dev.adsabs.harvard.edu`, try:

- [https://dev.adsabs.harvard.edu/search/q=star&rows=25&sort=date%20desc%2c%20bibcode%20desc&p_=0](https://dev.adsabs.harvard.edu/search/q=star&rows=25&sort=date%20desc%2c%20bibcode%20desc&p_=0)
- [https://dev.adsabs.harvard.edu/abs/2018EPJWC.18608001A/abstract](https://dev.adsabs.harvard.edu/abs/2018EPJWC.18608001A/abstract)
- [https://dev.adsabs.harvard.edu/abs/2018arXiv181205787Z/tableofcontents](https://dev.adsabs.harvard.edu/abs/2018arXiv181205787Z/tableofcontents)


## Testing

```
resty -I turbobee/  tests/test.lua
```

## Misc

How to reload nginx and all its lua modules:

```
/usr/local/openresty/nginx/sbin/nginx -s reload
```


