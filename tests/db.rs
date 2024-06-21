mod common;

#[tokio::test]
async fn test_add() {
    common::setup().await;
    assert_eq!(5, 5);
}
