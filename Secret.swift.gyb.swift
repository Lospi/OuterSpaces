%{
import os

def chunks(seq, size):
    return (seq[i:(i + size)] for i in range(0, len(seq), size))

def encode(string, cipher):
    bytes = string.encode("UTF-8")
    return [ord(bytes[i]) ^ cipher[i % len(cipher)] for i in range(0, len(bytes))]
}%
enum Secrets {
    private static let salt: [UInt8] = [
    %{ salt = [ord(byte) for byte in os.urandom(64)] }%
    % for chunk in chunks(salt, 8):
        ${"".join(["0x%02x, " % byte for byte in chunk])}
    % end
    ]

    static var chico_bento: String {
        let encoded: [UInt8] = [
        % for chunk in chunks(encode(os.environ.get('CHICO_BENTO'), salt), 8):
            ${"".join(["0x%02x, " % byte for byte in chunk])}
        % end
        ]

        return decode(encoded, cipher: salt)
    }
}
