use aiken/crypto.{VerificationKeyHash}
use cardano/transaction.{Transaction, OutputReference}
use vodka_extra_signatories.{key_signed}
use vodka_validity_range.{valid_after}

pub type StakeDatum {
  vester: VerificationKeyHash,
  vest_amount: Int,
  vest_start_time: Int,
  min_duration: Int
}

validator vest_x_time {
  spend(
    datum_opt: Option<StakeDatum>,
    _redeemer: Data,
    _input: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt

    let unlock_time = datum.vest_start_time + datum.min_duration

    and {
      key_signed(tx.extra_signatories, datum.vester),
      valid_after(tx.validity_range, unlock_time),
    }
  }

  else(_) {
    fail
  }
}
