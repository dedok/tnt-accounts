#!/usr/bin/env python

#
# Copyrights (C) 2017
#


import sys
import urllib2
import traceback
import urlparse
import json
import time

#
# Helpers
#
def get(url, verbose = False):
    out = ''
    try:
        res = urllib2.urlopen(urllib2.Request(url))
        out = res.read()
        out = out + res.read()
        rc = res.getcode()

        if verbose:
            print("url: ", url, " code: ", rc, " recv: '", out, "'")

        return (rc, out)
    except urllib2.HTTPError, e:
        if e.code == 400:
            out = e.read();

        if verbose:
            print("url: ", url, " code: ", e.code, " recv: '", out, "'")

        return (e.code, out)
    except Exception, e:
        print traceback.format_exc()
        return (False, e)


def post(url, data, verbose = False):
    out = '{}'
    try:
        req = urllib2.Request(url)
        req.add_header('Content-Type', 'application/json')

        res = urllib2.urlopen(req, json.dumps(data).encode('utf8'))
        out = res.read()
        out = out + res.read()
        rc = res.getcode()

        if verbose:
            print("code: ", rc, " recv: '", out, "'")

        return (rc, json.loads(out))
    except urllib2.HTTPError as e:
        if e.code == 400:
            out = e.read();
        return (e.code, json.loads(out))
    except Exception as e:
        print(traceback.format_exc())
        return (False, e)

## Test cases

#BASE_URL = 'http://sh2.tarantool.org/api'
BASE_URL = 'http://127.0.0.1:8081/api'

account_id = int(time.time())

print ('[+] /add/user')
url = BASE_URL + '/add/user'
user_params = {"params":[{"account_id": account_id, "user_name": "Vasiliy" }]}
rc, out = post(url, user_params)
print (rc, out)
assert rc == 200, 'rc != 200'
user_params['params'][0]['id'] = out['result'][0]['id']
assert user_params['params'] == out['result'], 'params != result'
print ('[+] OK')

print ('[+] /add/operations')
for _ in range(0, 10):
    url = BASE_URL + '/add/operation'
    opt_params = {"params":[{
        "account_id": account_id,
        "timestamp": int(time.time()) - _,
        "type": 0,
        "description": "Give me my money!!!!",
        "amount": 100500,
        "user_id": user_params['params'][0]['id']
    }]}
    rc, out = post(url, opt_params)
    opt_params['params'][0]['id'] = out['result'][1]['id']
    out['result'][1]['account_id'] = opt_params['params'][0]['account_id']
    assert rc == 200, 'rc != 200'
    assert user_params['params'][0] == out['result'][0] and \
            opt_params['params'][0] == out['result'][1], 'params != result'
print ('[+] OK')

print ('[+] /get/operations')
url = BASE_URL + '/get/operations?ts_start=0&ts_end=' + str(int(time.time()))
rc, out = get(url)
print ('[+] OK')

print ('[+] /get/account/operations')
url = BASE_URL + '/get/account/operations?account_id=' + str(account_id)
rc, out = get(url)
print ('[+] OK')

print ('[+] /get/account/balance')
url = BASE_URL + '/get/account/balance?account_id=' + str(account_id)
rc, out = get(url)
print ('[+] OK')
