import struct
import requests
from z3 import *

def col(code, string):
    return '\033[' + str(code) + 'm' + string + '\033[0m'

def base6(num):
    return ((num == 0) and '0') or (base6(num / 6).lstrip('0') + str(num % 6))

R = 31
B = 36
G = 32
Y = 33


# https://blog.securityevaluators.com/xorshift128-backward-ff3365dc0c17
def reverse17(val):
    return val ^ (val >> 17) ^ (val >> 34) ^ (val >> 51)
def reverse23(val):
    return (val ^ (val << 23) ^ (val << 46)) & 0xFFFFFFFFFFFFFFFF
def xs128p_backward(state0, state1):
    generated = (state0 + state1) & 0xFFFFFFFFFFFFFFFF
    prev_state1 = state0
    prev_state0 = state1 ^ (state0 >> 26)
    prev_state0 = prev_state0 ^ state0
    prev_state0 = reverse17(prev_state0)
    prev_state0 = reverse23(prev_state0)
    return prev_state0, prev_state1, generated

def main():
    cookies = None

    dubs = []
    for i in range(5):
        t = ''
        for j in range(16):
            print col(B, '[{:02d} / {:02d}] '.format(16*i + j + 1, 5*16)),
            cnt = 0
            while True:
                r = requests.post('http://34.85.75.40:10030/shot', cookies=cookies);
                if cookies is None:
                    cookies = r.cookies
                if r.text == 'bang!':
                    print col(R, r.text),
                    print ' '*(2*(6-cnt)), '=> {}'.format(cnt),
                    break
                cnt += 1
                print cnt,
            t += str(cnt)

            if (16*i + j <= 2):
                raw_input()
            else:
                print ''
        dubs.append(t)
    print ''

    print col(G, '[+] history')
    print col(G, '    ' + ''.join(dubs))
    raw_input()

    generated = []
    for dub in dubs:
        data1 = int(2 ** 52 * (int(dub, 6) / float(6 ** 16)))
        data2 = int(2 ** 52 * ((int(dub, 6) + 1) / float(6 ** 16)))
        assert (data1 & 0xFFFFFFFF00000) == (data2 & 0xFFFFFFFF00000)
        generated.append(data1 & 0xFFFFFFFF00000)

    # Backward
    generated = generated[::-1]

    state = [BitVec("state%d" % i, 64) for i in xrange(2)]
    initial_state0 = state[0]
    initial_state1 = state[1]
    s = Solver()

    # http://inaz2.hatenablog.com/entry/2016/03/07/194034
    for i in xrange(5):
        s1 = state[0]
        s0 = state[1]
        state[0] = s0
        s1 ^= (s1 << 23)
        state[1] = s1 ^ s0 ^ LShR(s1, 17) ^ LShR(s0, 26);
        output = state[1] + s0

        s.add((output & 0xFFFFFFFF00000) == int(generated[i]))

    print col(Y, '[*] calculating initial state...')

    assert s.check() == sat
    m = s.model()
    state0 = m[initial_state0].as_long()
    state1 = m[initial_state1].as_long()

    print col(G, '[+] SAT: state0 = {}, state1 = {}'.format(state0, state1))
    raw_input()

    generated = []
    while True:
        state0, state1, output = xs128p_backward(state0, state1)

        double_bits = (output & 0xFFFFFFFFFFFFF) | 0x3FF0000000000000
        double = struct.unpack('d', struct.pack('<Q', double_bits))[0] - 1
        predicted = base6(int(double * (6 ** 16))).zfill(16)

        for char in list(predicted):
            tries = int(char)
            print col(B, char),
            for i in range(tries):
                r = requests.post('http://34.85.75.40:10030/shot', cookies=cookies);
                if r.text.startswith('TSG'):
                    print ''
                    print col('97;41', r.text)
                    exit(0)
                print col(Y, '${}'.format(r.text)),
            r = requests.post('http://34.85.75.40:10030/roll', cookies=cookies);
            print r.text

main()
