function plot_target_point_cloud(detections, figureOpts, resultsDir)
%PLOT_TARGET_POINT_CLOUD Plot lateral/forward position and radial velocity.
if isempty(detections)
    return;
end
angle = detections.SelectedAngle_deg;
if ismember('RangeRefined_m', detections.Properties.VariableNames)
    rangeValue = detections.RangeRefined_m;
    velocityValue = detections.VelocityRefined_mps;
else
    rangeValue = detections.Range_m;
    velocityValue = detections.Velocity_mps;
end
x = rangeValue .* sind(angle);
y = rangeValue .* cosd(angle);
fig = figure('Name','Target Point Cloud','Visible',figureOpts.visible);
valid = isfinite(x) & isfinite(y) & isfinite(velocityValue);
if any(valid)
    scatter3(x(valid), y(valid), velocityValue(valid), 55, detections.SNR_dB(valid), 'filled');
else
    text(0.5,0.5,'No verified spatial positions available', ...
        'Units','normalized','HorizontalAlignment','center');
end
grid on; xlabel('Lateral x (m)'); ylabel('Forward y (m)');
zlabel('Radial velocity (m/s)'); title('Detected target point cloud');
colorbar;
save_result_figure(fig, fullfile(resultsDir,'target_point_cloud.png'), figureOpts);
end
