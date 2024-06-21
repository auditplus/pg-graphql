mod common;

#[tokio::test]
async fn test_init() {
    common::setup().await;

    assert_eq!(5, 5);
}
