use openrgb2::{OpenRgbClient, OpenRgbResult, Color, ControllerGroup};
use std::time::Duration;
use tokio::time::sleep;

#[tokio::main]
async fn main() -> OpenRgbResult<()> {
    let client = OpenRgbClient::connect().await?;
	let controllers = client.get_all_controllers().await?;
	wave_effect(&controllers).await
}

async fn wave_effect(controllers: &ControllerGroup) -> OpenRgbResult<()> {
	let mut offset: f32 = 0.0;
	let wave_length: f32 = 20.0; // higher is smoother, lower is jerkier

	loop {
		for controller in controllers {
			let led_count = controller.led_iter().count();
			let mut colors: Vec<Color> = Vec::with_capacity(led_count);

			for led_index in 0..led_count {
				let wave = (((led_index as f32 / wave_length) + offset).sin() + 1.0) / 2.0;
				let color = Color {
					r: (255.0 * wave) as u8,
					g: (128.0 * (1.0 - wave)) as u8,
					b: 255
				};
				colors.push(color);
			}

			let mut cmd = controller.cmd();
			for (i, &color) in colors.iter().enumerate() {
				cmd.set_led(i, color)?;
			}
			cmd.execute().await?;
		}

		offset += 0.15;
		sleep(Duration::from_millis(50)).await;
	}
}
