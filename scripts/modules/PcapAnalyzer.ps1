# PcapAnalyzer.ps1 - Lecture d'une capture pcap et décodage des échanges DNS, TCP, SSH et TLS (sans Wireshark)
# Ne produit que des faits ; leur interprétation (diagnostic) appartient à DiagnosticReport.ps1.
# Le décodage binaire est en C# (compilé à la volée par Add-Type) : en PowerShell, chaque appel de fonction
# recevant le tableau d'octets coûte jusqu'à plusieurs dizaines de millisecondes, soit des minutes par capture.

$Script:PcapErrorKind = @{ CaptureUnsupported = "CaptureUnsupported" }

$Script:TlsVersionNames = @{ 0x0300 = "SSL 3.0"; 0x0301 = "TLS 1.0"; 0x0302 = "TLS 1.1"; 0x0303 = "TLS 1.2"; 0x0304 = "TLS 1.3" }
$Script:TlsAlertNames   = @{
    0 = "close_notify"; 10 = "unexpected_message"; 20 = "bad_record_mac"; 40 = "handshake_failure"; 42 = "bad_certificate"
    43 = "unsupported_certificate"; 44 = "certificate_revoked"; 45 = "certificate_expired"; 46 = "certificate_unknown"
    47 = "illegal_parameter"; 48 = "unknown_ca"; 50 = "decode_error"; 51 = "decrypt_error"; 70 = "protocol_version"
    71 = "insufficient_security"; 80 = "internal_error"; 86 = "inappropriate_fallback"; 112 = "unrecognized_name"
    116 = "certificate_required"; 120 = "no_application_protocol"
}
$Script:TlsAlertCloseNotify = 0

$Script:DnsResolution = @{ NotSeen = "NotSeen"; NoAnswer = "NoAnswer"; NxDomain = "NxDomain"; NoAddress = "NoAddress"; Resolved = "Resolved" }
$Script:DnsRcodeNxDomain = 3

$Script:PcapDecoderSource = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace EwonDiagnostics
{
    public class Packet
    {
        public double Time;
        public int Protocol;
        public string Src;
        public string Dst;
        public int SrcPort;
        public int DstPort;
        public long Seq;
        public int Flags;
        public byte[] Payload;
    }

    public class Capture
    {
        public long LinkType;
        public bool LinkTypeSupported;
        public int FrameCount;
        public double DurationSeconds;
        public List<Packet> Packets = new List<Packet>();
    }

    internal static class Bin
    {
        public static int U16(byte[] b, int o) { return (b[o] << 8) | b[o + 1]; }
        public static long U32(byte[] b, int o) { return ((long)b[o] << 24) | ((long)b[o + 1] << 16) | ((long)b[o + 2] << 8) | b[o + 3]; }
        public static long U32Le(byte[] b, int o) { return ((long)b[o + 3] << 24) | ((long)b[o + 2] << 16) | ((long)b[o + 1] << 8) | b[o]; }
        public static string IPv4(byte[] b, int o) { return b[o] + "." + b[o + 1] + "." + b[o + 2] + "." + b[o + 3]; }

        public static byte[] Slice(byte[] b, int start, int end)
        {
            int length = Math.Max(0, Math.Min(end, b.Length) - start);
            byte[] copy = new byte[length];
            if (length > 0) Buffer.BlockCopy(b, start, copy, 0, length);
            return copy;
        }
    }

    public static class PcapReader
    {
        public const int LinkTypeEthernet = 1;
        public const int LinkTypeLinuxSll = 113;
        public const int ProtocolTcp = 6;
        public const int ProtocolUdp = 17;
        const int GlobalHeaderLength = 24;
        const int RecordHeaderLength = 16;
        const int LinkTypeOffset = 20;
        const int EthernetHeaderLength = 14;
        const int VlanTagLength = 4;
        const int SllHeaderLength = 16;
        const int EtherTypeIPv4 = 0x0800;
        const int EtherTypeVlan = 0x8100;
        const int IPv4MinHeaderLength = 20;
        const int TcpMinHeaderLength = 20;
        const int UdpHeaderLength = 8;
        const int FragmentOffsetMask = 0x1FFF;
        const uint MagicMicroseconds = 0xA1B2C3D4;
        const uint MagicNanoseconds = 0xA1B23C4D;

        public static Capture Read(byte[] bytes)
        {
            Capture capture = new Capture();
            if (bytes.Length < GlobalHeaderLength) return capture;
            uint littleEndianMagic = (uint)Bin.U32Le(bytes, 0);
            bool bigEndian = littleEndianMagic != MagicMicroseconds && littleEndianMagic != MagicNanoseconds;
            uint magic = bigEndian ? (uint)Bin.U32(bytes, 0) : littleEndianMagic;
            double fractionScale = magic == MagicNanoseconds ? 1e9 : 1e6;
            Func<int, long> u32 = o => bigEndian ? Bin.U32(bytes, o) : Bin.U32Le(bytes, o);

            capture.LinkType = u32(LinkTypeOffset);
            capture.LinkTypeSupported = capture.LinkType == LinkTypeEthernet || capture.LinkType == LinkTypeLinuxSll;
            if (!capture.LinkTypeSupported) return capture;

            double firstTime = -1;
            double lastTime = 0;
            int offset = GlobalHeaderLength;
            while (offset + RecordHeaderLength <= bytes.Length)
            {
                double time = u32(offset) + u32(offset + 4) / fractionScale;
                long frameEnd = offset + RecordHeaderLength + u32(offset + 8);
                int frame = offset + RecordHeaderLength;
                if (frameEnd > bytes.Length) break;
                offset = (int)frameEnd;
                capture.FrameCount++;
                if (firstTime < 0) firstTime = time;
                lastTime = time;

                int ip = IPv4Offset(bytes, frame, (int)frameEnd, (int)capture.LinkType);
                if (ip < 0) continue;
                Packet packet = ParseIPv4(bytes, ip, (int)frameEnd, time);
                if (packet != null) capture.Packets.Add(packet);
            }
            capture.DurationSeconds = firstTime < 0 ? 0 : lastTime - firstTime;
            return capture;
        }

        static int IPv4Offset(byte[] b, int frame, int frameEnd, int linkType)
        {
            int typeOffset;
            int ip;
            if (linkType == LinkTypeLinuxSll)
            {
                typeOffset = frame + SllHeaderLength - 2;
                ip = frame + SllHeaderLength;
            }
            else
            {
                typeOffset = frame + EthernetHeaderLength - 2;
                ip = frame + EthernetHeaderLength;
                if (typeOffset + 2 <= frameEnd && Bin.U16(b, typeOffset) == EtherTypeVlan)
                {
                    typeOffset += VlanTagLength;
                    ip += VlanTagLength;
                }
            }
            if (typeOffset + 2 > frameEnd || Bin.U16(b, typeOffset) != EtherTypeIPv4) return -1;
            return ip + IPv4MinHeaderLength <= frameEnd ? ip : -1;
        }

        static Packet ParseIPv4(byte[] b, int ip, int frameEnd, double time)
        {
            if ((b[ip] >> 4) != 4) return null;
            // Les fragments suivants n'ont pas d'en-tête de transport.
            if ((Bin.U16(b, ip + 6) & FragmentOffsetMask) != 0) return null;
            int protocol = b[ip + 9];
            if (protocol != ProtocolTcp && protocol != ProtocolUdp) return null;
            int transport = ip + (b[ip] & 0x0F) * 4;
            int end = Math.Min(ip + Bin.U16(b, ip + 2), frameEnd);
            if (transport + (protocol == ProtocolTcp ? TcpMinHeaderLength : UdpHeaderLength) > end) return null;

            Packet packet = new Packet
            {
                Time = time,
                Protocol = protocol,
                Src = Bin.IPv4(b, ip + 12),
                Dst = Bin.IPv4(b, ip + 16),
                SrcPort = Bin.U16(b, transport),
                DstPort = Bin.U16(b, transport + 2)
            };
            int payloadStart;
            if (protocol == ProtocolTcp)
            {
                packet.Seq = Bin.U32(b, transport + 4);
                packet.Flags = b[transport + 13];
                payloadStart = transport + (b[transport + 12] >> 4) * 4;
            }
            else
            {
                payloadStart = transport + UdpHeaderLength;
            }
            packet.Payload = Bin.Slice(b, payloadStart, end);
            return packet;
        }
    }

    public class DnsMessage
    {
        public string Name;
        public bool IsResponse;
        public int Rcode;
        public List<string> Addresses = new List<string>();
    }

    public static class DnsDecoder
    {
        public const int Port = 53;
        const int HeaderLength = 12;
        const int ResponseFlag = 0x8000;
        const int RcodeMask = 0x000F;
        const int RecordTypeA = 1;
        const int QuestionTrailerLength = 4;
        const int AnswerFixedLength = 10;
        const int PointerMask = 0xC0;
        const int PointerOffsetMask = 0x3FFF;
        const int MaxPointerJumps = 16;

        public static List<DnsMessage> Parse(List<Packet> packets)
        {
            List<DnsMessage> messages = new List<DnsMessage>();
            foreach (Packet packet in packets)
            {
                if (packet.Protocol != PcapReader.ProtocolUdp || (packet.SrcPort != Port && packet.DstPort != Port)) continue;
                try
                {
                    DnsMessage message = ParseMessage(packet.Payload);
                    if (message != null) messages.Add(message);
                }
                catch (IndexOutOfRangeException) { /* message tronqué par la capture */ }
                catch (ArgumentException) { /* message tronqué par la capture */ }
            }
            return messages;
        }

        static DnsMessage ParseMessage(byte[] d)
        {
            if (d.Length < HeaderLength) return null;
            int flags = Bin.U16(d, 2);
            int questionCount = Bin.U16(d, 4);
            int answerCount = Bin.U16(d, 6);
            if (questionCount < 1) return null;

            int next;
            DnsMessage message = new DnsMessage
            {
                Name = ReadName(d, HeaderLength, out next),
                IsResponse = (flags & ResponseFlag) != 0,
                Rcode = flags & RcodeMask
            };
            int position = next + QuestionTrailerLength;
            for (int i = 0; i < answerCount; i++)
            {
                ReadName(d, position, out next);
                int type = Bin.U16(d, next);
                int dataLength = Bin.U16(d, next + 8);
                int data = next + AnswerFixedLength;
                if (type == RecordTypeA && dataLength == 4) message.Addresses.Add(Bin.IPv4(d, data));
                position = data + dataLength;
            }
            return message;
        }

        static string ReadName(byte[] d, int offset, out int next)
        {
            List<string> labels = new List<string>();
            next = -1;
            int jumps = 0;
            int position = offset;
            while (true)
            {
                int length = d[position];
                if (length == 0) { position++; break; }
                if ((length & PointerMask) == PointerMask)
                {
                    // Borne les sauts : un message malformé pourrait pointer sur lui-même.
                    if (++jumps > MaxPointerJumps) break;
                    if (next < 0) next = position + 2;
                    position = Bin.U16(d, position) & PointerOffsetMask;
                    continue;
                }
                labels.Add(Encoding.ASCII.GetString(d, position + 1, length));
                position += 1 + length;
            }
            if (next < 0) next = position;
            return string.Join(".", labels);
        }
    }

    public class TcpClose
    {
        public string By;
        public string Kind;
        public double ElapsedSeconds;
    }

    public class TcpConnection
    {
        public string Client;
        public int ClientPort;
        public string Server;
        public int ServerPort;
        public double StartTime;
        public int SynCount;
        public bool SynAcked;
        public TcpClose Close;
        public byte[] ClientStream;
        public byte[] ServerStream;
        internal long ClientIsn = -1;
        internal long ServerIsn = -1;
        internal List<Packet> ClientSegments = new List<Packet>();
        internal List<Packet> ServerSegments = new List<Packet>();
    }

    public static class TcpDecoder
    {
        public const string Client = "Client";
        public const string Server = "Server";
        public const string Fin = "FIN";
        public const string Rst = "RST";
        const int FlagFin = 0x01;
        const int FlagSyn = 0x02;
        const int FlagRst = 0x04;
        const int FlagAck = 0x10;
        const long SequenceMask = 0xFFFFFFFF;

        public static List<TcpConnection> GetConnections(List<Packet> packets, int serverPort, string[] serverAddresses)
        {
            HashSet<string> addresses = new HashSet<string>(serverAddresses ?? new string[0]);
            Dictionary<string, TcpConnection> byKey = new Dictionary<string, TcpConnection>();
            List<TcpConnection> connections = new List<TcpConnection>();
            foreach (Packet packet in packets)
            {
                if (packet.Protocol != PcapReader.ProtocolTcp) continue;
                bool fromClient;
                if (packet.DstPort == serverPort && (addresses.Count == 0 || addresses.Contains(packet.Dst))) fromClient = true;
                else if (packet.SrcPort == serverPort && (addresses.Count == 0 || addresses.Contains(packet.Src))) fromClient = false;
                else continue;

                string client = fromClient ? packet.Src : packet.Dst;
                int clientPort = fromClient ? packet.SrcPort : packet.DstPort;
                string server = fromClient ? packet.Dst : packet.Src;
                string key = client + ":" + clientPort + ">" + server;
                bool syn = (packet.Flags & FlagSyn) != 0;
                bool ack = (packet.Flags & FlagAck) != 0;
                TcpConnection connection;
                if (!byKey.TryGetValue(key, out connection))
                {
                    // Seules comptent les connexions ouvertes pendant la capture : un flux déjà établi n'est pas le test.
                    if (!(fromClient && syn && !ack)) continue;
                    connection = new TcpConnection { Client = client, ClientPort = clientPort, Server = server, ServerPort = serverPort, StartTime = packet.Time };
                    byKey[key] = connection;
                    connections.Add(connection);
                }

                if (syn && !ack)
                {
                    connection.SynCount++;
                    connection.ClientIsn = packet.Seq;
                }
                if (syn && ack)
                {
                    connection.SynAcked = true;
                    connection.ServerIsn = packet.Seq;
                }
                if (packet.Payload.Length > 0) (fromClient ? connection.ClientSegments : connection.ServerSegments).Add(packet);
                if (connection.Close == null && (packet.Flags & (FlagFin | FlagRst)) != 0)
                {
                    connection.Close = new TcpClose
                    {
                        By = fromClient ? Client : Server,
                        Kind = (packet.Flags & FlagRst) != 0 ? Rst : Fin,
                        ElapsedSeconds = packet.Time - connection.StartTime
                    };
                }
            }
            foreach (TcpConnection connection in connections)
            {
                connection.ClientStream = Join(connection.ClientSegments, connection.ClientIsn);
                connection.ServerStream = Join(connection.ServerSegments, connection.ServerIsn);
            }
            return connections;
        }

        // Remet le flux dans l'ordre à partir du numéro de séquence initial (SYN + 1), modulo 2^32, en ignorant
        // les retransmissions ; s'arrête au premier trou (paquet perdu par la capture).
        static byte[] Join(List<Packet> packets, long isn)
        {
            MemoryStream stream = new MemoryStream();
            if (isn < 0) return stream.ToArray();
            SortedDictionary<long, byte[]> segments = new SortedDictionary<long, byte[]>();
            foreach (Packet packet in packets)
            {
                long offset = (packet.Seq - (isn + 1)) & SequenceMask;
                if (!segments.ContainsKey(offset)) segments[offset] = packet.Payload;
            }
            long expected = 0;
            foreach (KeyValuePair<long, byte[]> segment in segments)
            {
                if (segment.Key > expected) break;
                long skip = expected - segment.Key;
                if (skip >= segment.Value.Length) continue;
                stream.Write(segment.Value, (int)skip, segment.Value.Length - (int)skip);
                expected = segment.Key + segment.Value.Length;
            }
            return stream.ToArray();
        }
    }

    public class SshHandshake
    {
        public string Banner;
        public Dictionary<string, string[]> KexInit;
        public long? DisconnectCode;
        public string DisconnectDescription;
        public bool NewKeys;
    }

    public static class SshDecoder
    {
        public static readonly string[] Categories = { "Kex", "HostKey", "EncryptionC2S", "EncryptionS2C", "MacC2S", "MacS2C", "CompressionC2S", "CompressionS2C" };
        const int MessageDisconnect = 1;
        const int MessageKexInit = 20;
        const int MessageNewKeys = 21;
        const int MaxCleartextPacket = 35000;
        const int KexInitCookieLength = 16;
        const string BannerPrefix = "SSH-";

        public static SshHandshake Parse(byte[] s)
        {
            SshHandshake handshake = new SshHandshake();
            // Des lignes peuvent précéder la bannière « SSH-… » (RFC 4253).
            int position = 0;
            while (position < s.Length)
            {
                int lineEnd = Array.IndexOf(s, (byte)'\n', position);
                if (lineEnd < 0) return handshake;
                string line = Encoding.ASCII.GetString(s, position, lineEnd - position).TrimEnd('\r');
                position = lineEnd + 1;
                if (line.StartsWith(BannerPrefix)) { handshake.Banner = line; break; }
            }

            try
            {
                while (position + 6 <= s.Length)
                {
                    long packetLength = Bin.U32(s, position);
                    if (packetLength <= 0 || packetLength > MaxCleartextPacket || position + 4 + packetLength > s.Length) break;
                    int message = s[position + 5];
                    int body = position + 6;
                    if (message == MessageKexInit)
                    {
                        // Rempli à part puis publié d'un coup : un KEXINIT tronqué ne laisse pas de liste partielle.
                        int cursor = body + KexInitCookieLength;
                        Dictionary<string, string[]> kexInit = new Dictionary<string, string[]>();
                        foreach (string category in Categories)
                        {
                            int length = (int)Bin.U32(s, cursor);
                            kexInit[category] = Encoding.ASCII.GetString(s, cursor + 4, length).Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                            cursor += 4 + length;
                        }
                        handshake.KexInit = kexInit;
                    }
                    else if (message == MessageDisconnect)
                    {
                        handshake.DisconnectCode = Bin.U32(s, body);
                        handshake.DisconnectDescription = Encoding.UTF8.GetString(s, body + 8, (int)Bin.U32(s, body + 4));
                    }
                    else if (message == MessageNewKeys)
                    {
                        // La suite est chiffrée.
                        handshake.NewKeys = true;
                        break;
                    }
                    position += 4 + (int)packetLength;
                }
            }
            catch (IndexOutOfRangeException) { /* paquet tronqué par la capture */ }
            catch (ArgumentException) { /* paquet tronqué par la capture */ }
            return handshake;
        }
    }

    public class TlsHandshake
    {
        public int? HelloVersion;
        public int? Suite;
        public string ServerName;
        public List<int> SupportedVersions = new List<int>();
        public int? AlertDescription;
        public bool ChangeCipherSpec;
        public bool ApplicationData;
    }

    public static class TlsDecoder
    {
        const int ContentChangeCipherSpec = 20;
        const int ContentAlert = 21;
        const int ContentHandshake = 22;
        const int ContentApplicationData = 23;
        const int RecordHeaderLength = 5;
        const int HandshakeHeaderLength = 4;
        const int AlertLength = 2;
        const int RandomLength = 32;
        const int HandshakeClientHello = 1;
        const int HandshakeServerHello = 2;
        const int ExtensionServerName = 0;
        const int ExtensionSupportedVersions = 43;
        const int ServerNameEntryHeaderLength = 5;

        public static TlsHandshake Parse(byte[] s, bool isClient)
        {
            TlsHandshake handshake = new TlsHandshake();
            MemoryStream messages = new MemoryStream();
            try
            {
                int position = 0;
                while (position + RecordHeaderLength <= s.Length)
                {
                    int contentType = s[position];
                    int length = Bin.U16(s, position + 3);
                    int body = position + RecordHeaderLength;
                    if (body + length > s.Length) break;
                    if (contentType == ContentHandshake)
                    {
                        // Après ChangeCipherSpec, les messages sont chiffrés.
                        if (!handshake.ChangeCipherSpec) messages.Write(s, body, length);
                    }
                    else if (contentType == ContentAlert)
                    {
                        // Octet 1 : niveau, octet 2 : description ; après ChangeCipherSpec, l'alerte est chiffrée.
                        if (!handshake.ChangeCipherSpec && length == AlertLength) handshake.AlertDescription = s[body + 1];
                    }
                    else if (contentType == ContentChangeCipherSpec) handshake.ChangeCipherSpec = true;
                    else if (contentType == ContentApplicationData) handshake.ApplicationData = true;
                    else break;
                    position = body + length;
                }

                byte[] buffer = messages.ToArray();
                int cursor = 0;
                while (cursor + HandshakeHeaderLength <= buffer.Length)
                {
                    int type = buffer[cursor];
                    int length = (buffer[cursor + 1] << 16) | Bin.U16(buffer, cursor + 2);
                    int body = cursor + HandshakeHeaderLength;
                    if (body + length > buffer.Length) break;
                    if (type == HandshakeClientHello || type == HandshakeServerHello) ReadHello(handshake, Bin.Slice(buffer, body, body + length), isClient);
                    cursor = body + length;
                }
            }
            catch (IndexOutOfRangeException) { /* enregistrement tronqué par la capture */ }
            catch (ArgumentException) { /* enregistrement tronqué par la capture */ }
            return handshake;
        }

        static void ReadHello(TlsHandshake handshake, byte[] b, bool isClient)
        {
            handshake.HelloVersion = Bin.U16(b, 0);
            int cursor = 2 + RandomLength;
            cursor += 1 + b[cursor];
            if (isClient)
            {
                cursor += 2 + Bin.U16(b, cursor);
                cursor += 1 + b[cursor];
            }
            else
            {
                handshake.Suite = Bin.U16(b, cursor);
                cursor += 3;
            }
            if (cursor + 2 > b.Length) return;
            int end = Math.Min(b.Length, cursor + 2 + Bin.U16(b, cursor));
            cursor += 2;
            while (cursor + 4 <= end)
            {
                int type = Bin.U16(b, cursor);
                int length = Bin.U16(b, cursor + 2);
                int data = cursor + 4;
                // Le serveur renvoie une extension SNI vide pour accuser réception : seul le client porte le nom.
                if (type == ExtensionServerName && isClient && length >= ServerNameEntryHeaderLength)
                {
                    handshake.ServerName = Encoding.ASCII.GetString(b, data + ServerNameEntryHeaderLength, Bin.U16(b, data + 3));
                }
                else if (type == ExtensionSupportedVersions)
                {
                    // Côté client : une longueur sur 1 octet puis la liste ; côté serveur : la version retenue.
                    int start = isClient ? data + 1 : data;
                    for (int i = start; i + 1 < data + length; i += 2) handshake.SupportedVersions.Add(Bin.U16(b, i));
                }
                cursor = data + length;
            }
        }
    }

    public class FlowCount
    {
        public string Flow;
        public int Packets;
    }

    public static class CaptureSummary
    {
        // Conversations les plus bavardes, sens confondus, identifiées par le port le plus bas (celui du service).
        public static List<FlowCount> TopFlows(List<Packet> packets, int count)
        {
            Dictionary<string, int> counts = new Dictionary<string, int>();
            foreach (Packet p in packets)
            {
                string protocol = p.Protocol == PcapReader.ProtocolTcp ? "TCP" : "UDP";
                string key = p.SrcPort < p.DstPort
                    ? p.Dst + " <-> " + p.Src + ":" + p.SrcPort + "/" + protocol
                    : p.Src + " <-> " + p.Dst + ":" + p.DstPort + "/" + protocol;
                int current;
                counts.TryGetValue(key, out current);
                counts[key] = current + 1;
            }
            List<FlowCount> flows = new List<FlowCount>();
            foreach (KeyValuePair<string, int> entry in counts) flows.Add(new FlowCount { Flow = entry.Key, Packets = entry.Value });
            flows.Sort((a, b) => b.Packets.CompareTo(a.Packets));
            return flows.GetRange(0, Math.Min(count, flows.Count));
        }
    }
}
'@

function Initialize-PcapDecoder {
    if (-not ('EwonDiagnostics.PcapReader' -as [type])) {
        Add-Type -TypeDefinition $Script:PcapDecoderSource -Language CSharp
    }
}

function Read-PcapCapture {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    Initialize-PcapDecoder
    $capture = [EwonDiagnostics.PcapReader]::Read($Bytes)
    if (-not $capture.LinkTypeSupported) {
        throw (New-EwonException -Kind $Script:PcapErrorKind.CaptureUnsupported -Detail $capture.LinkType)
    }
    return $capture
}

function Get-DnsResolution {
    param($Messages, [Parameter(Mandatory)][string]$HostName)
    $forHost = @($Messages | Where-Object { $_.Name -eq $HostName })
    $responses = @($forHost | Where-Object { $_.IsResponse })
    $addresses = @($responses | ForEach-Object { $_.Addresses } | Select-Object -Unique)

    $status = $Script:DnsResolution.NotSeen
    if ($addresses.Count -gt 0) {
        $status = $Script:DnsResolution.Resolved
    } elseif ($responses | Where-Object { $_.Rcode -eq $Script:DnsRcodeNxDomain }) {
        $status = $Script:DnsResolution.NxDomain
    } elseif ($responses.Count -gt 0) {
        $status = $Script:DnsResolution.NoAddress
    } elseif ($forHost.Count -gt 0) {
        $status = $Script:DnsResolution.NoAnswer
    }
    return @{ Status = $status; Addresses = [string[]]$addresses }
}

function Get-TlsVersionName {
    param([int]$Version)
    if ($Script:TlsVersionNames.ContainsKey($Version)) { return $Script:TlsVersionNames[$Version] }
    return "0x{0:X4}" -f $Version
}

function Get-TlsAlertName {
    param([int]$Description)
    if ($Script:TlsAlertNames.ContainsKey($Description)) { return $Script:TlsAlertNames[$Description] }
    return "$Description"
}
