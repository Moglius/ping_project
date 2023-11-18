import argparse

ACCOUNTS = {
    "FI_Workloads_DEV",
    "FI_Workloads_TST",
    "FI_Workloads_PRD"
}

OS = {"windows", "linux"}

def load_argparser():
    parser = argparse.ArgumentParser()

    parser.add_argument('-A', '--account', action='store',
                        dest='account',
                        choices=ACCOUNTS,
                        help='Target Account.',
                        required=True)

    parser.add_argument('-S', '--servers', action='store',
                        dest='servers',
                        help='Comma separated list of servers in FQDN.',
                        required=True)

    parser.add_argument('-o', action='store',
                        dest='os',
                        choices=OS,
                        help='Select OS type: windows or linux',
                        required=True)

    parser.add_argument('-R', '--region', action='store',
                        dest='region',
                        help='Region where servers will be lift and shifted.',
                        required=True)

    return parser.parse_args()

if __name__ == "__main__":
    parser = load_argparser()
    print(parser.region)
